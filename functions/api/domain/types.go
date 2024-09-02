package domain

type TenantBase struct {
	Name string `json:"name"`
}

type NewTenantDto struct {
	TenantBase
	SubscriptionPlan string `json:"subscriptionPlan"`
}

type NewSubscriptionDto struct {
	SubscriptionPlan string `json:"subscriptionPlan"`
	Tenant           string `json:"tenant"`
}

type PermissionDto struct {
	Name        string   `json:"name"`
	Actions     []string `json:"actions"`
	Memberships []string `json:"memberships"`
	Targets     []string `json:"targets"`
}
