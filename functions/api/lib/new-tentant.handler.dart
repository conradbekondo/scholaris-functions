import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:scholaris_api/types.dart';

const _tenantsCollectionId = 'organizations';
const _permissionsCollection = 'permissions';
// const _plansCollection = 'subscription_plans';
const _subscriptionsCollection = 'billing_subscriptions';
const _dbId = '6587eefbaf2d45dc4407';

Future<dynamic>? createTenant(RequestContext context) async {
  final req = context.req;
  final user = context.user;

  if (req.body == null) {
    throw ExecutionException('Empty Request Body', status: 400);
  }
  if (user == null) {
    throw ExecutionException('401 - Unauthorized', status: 401);
  }

  final name = req.body?['name'] as String?;
  final subscriptionPlan = req.body?['subscriptionPlan'] as String?;

  if (name == null || name.isEmpty) {
    throw ExecutionException('"name" field is required', status: 400);
  }
  if (subscriptionPlan == null || subscriptionPlan.isEmpty) {
    throw ExecutionException('"subscriptionPlan" field is required',
        status: 400);
  }

  final db = Databases(context.client);
  final tenantDoc = await db.createDocument(
      databaseId: _dbId,
      collectionId: _tenantsCollectionId,
      documentId: ID.unique(),
      data: {name: name},
      permissions: [Permission.read(Role.user(user.$id))]) as Tenant;

  final teams = Teams(context.client);
  final team = await teams.create(
      name: tenantDoc.data['name'],
      teamId: tenantDoc.$id,
      roles: [Role.user(user.$id, 'owner')]);
  final memberships = await teams.listMemberships(
      teamId: team.$id, queries: [Query.equal('userId', user.$id)]);

  await db.createDocument(
      databaseId: _dbId,
      collectionId: _subscriptionsCollection,
      documentId: ID.unique(),
      data: {
        'subscriptionPlan': subscriptionPlan,
        'tenant': tenantDoc.$id
      },
      permissions: [
        Permission.read(Role.team(team.$id, 'owner')),
        Permission.update(Role.team(team.$id, 'owner'))
      ]);

  final prefix = ResourceStringBuilder.create('')
      .type(ResourceType.tenants)
      .resource(tenantDoc.$id)
      .build();

  final rootPermission = {
    'name': 'Root Permission',
    'actions': [
      PlatformAction.Update,
      PlatformAction.Delete,
      PlatformAction.Read,
    ],
    'memberships': [memberships.memberships[0].$id],
    'targets': ResourceType.values.map((type) {
      return ResourceStringBuilder.create(prefix)
          .type(type)
          .resource(anyResource)
          .build();
    })
  };

  await db.createDocument(
      databaseId: _dbId,
      collectionId: _permissionsCollection,
      documentId: ID.unique(),
      data: rootPermission);

  return tenantDoc;
}
