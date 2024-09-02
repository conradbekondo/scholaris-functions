package handlers

import (
	"errors"
	"openruntimes/handler/domain"
	"openruntimes/handler/domain/resources"

	"github.com/appwrite/sdk-for-go/client"
	"github.com/appwrite/sdk-for-go/databases"
	"github.com/appwrite/sdk-for-go/id"
	"github.com/appwrite/sdk-for-go/models"
	"github.com/appwrite/sdk-for-go/permission"
	"github.com/appwrite/sdk-for-go/role"
	"github.com/appwrite/sdk-for-go/teams"
	"github.com/open-runtimes/types-for-go/v4/openruntimes"
)

const maintainerRole = "maintainer"
const adminRole = "admin"

const _tenantsCollectionId = "organizations"
const _permissionsCollection = "permissions"

// const _plansCollection = "subscription_plans";
const _subscriptionsCollection = "billing_subscriptions"
const _dbId = "6587eefbaf2d45dc4407"

var tenantMembershipRoles = []string{maintainerRole, adminRole}

func CreateTenant(context openruntimes.Context, client *client.Client, user *models.User) (*models.Document, error) {
	if user == nil {
		return nil, errors.New("401 - Unauthorized access")
	}

	body, parseOk := context.Req.Body().(domain.NewTenantDto)
	if !parseOk {
		return nil, errors.New("Invalid request")
	}

	var err error
	var team *models.Team
	var membership *models.Membership
	var tenantDoc *models.Document

	db := databases.New(*client)
	_teams := teams.New(*client)

	team, err = _teams.Create(
		id.Unique(),
		body.Name,
		_teams.WithCreateRoles(tenantMembershipRoles),
	)

	if err != nil {
		return nil, err
	}

	membership, err = _teams.CreateMembership(
		team.Id,
		[]string{"owner"},
		_teams.WithCreateMembershipUserId(user.Id),
	)

	tenantDoc, err = db.CreateDocument(
		_dbId,
		_tenantsCollectionId,
		team.Id,
		domain.TenantBase{
			Name: body.Name,
		},
		db.WithCreateDocumentPermissions([]string{
			permission.Read(role.Team(team.Id, maintainerRole)),
			permission.Read(role.Team(team.Id, adminRole)),
			permission.Read(role.Team(team.Id, "owner")),
			permission.Update(role.Team(team.Id, maintainerRole)),
			permission.Update(role.Team(team.Id, adminRole)),
			permission.Delete(role.Team(team.Id, "owner")),
		}),
	)

	if err != nil {
		return nil, err
	}

	var _ *models.Document
	_, err = db.CreateDocument(
		_dbId,
		_subscriptionsCollection,
		id.Unique(),
		domain.NewSubscriptionDto{
			SubscriptionPlan: body.SubscriptionPlan,
			Tenant:           tenantDoc.Id,
		},
		db.WithCreateDocumentPermissions([]string{
			permission.Read(role.Team(team.Id, "owner")),
			permission.Read(role.Team(team.Id, maintainerRole)),
			permission.Update(role.Team(team.Id, "owner")),
		}),
	)

	if err != nil {
		return nil, err
	}

	prefix := resources.FromType(resources.Tenants).Value(tenantDoc.Id).Build()

	rootPermission := domain.PermissionDto{
		Name:        "Root Permission",
		Actions:     []string{"create", "read", "update", "delete"},
		Memberships: []string{membership.Id},
		Targets: []string{
			resources.FromValue(prefix).Type(resources.Resources).Value(resources.AnyResource).Build(),
			resources.FromValue(prefix).Type(resources.Institutions).Value(resources.AnyResource).Build(),
		},
	}

	_, err = db.CreateDocument(_dbId, _permissionsCollection, id.Unique(), rootPermission)
	if err != nil {
		return nil, err
	}

	return tenantDoc, nil
}
