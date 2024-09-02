package handler

import (
	"fmt"
	"openruntimes/handler/handlers"
	"os"
	"regexp"
	"strings"

	"github.com/appwrite/sdk-for-go/appwrite"
	"github.com/appwrite/sdk-for-go/models"
	"github.com/open-runtimes/types-for-go/v4/openruntimes"
)

// This Appwrite function will be executed every time your function is triggered
func Main(context openruntimes.Context) openruntimes.Response {
	// You can use the Appwrite SDK to interact with other services
	// For this example, we're using the Users service
	client := appwrite.NewClient(
		appwrite.WithEndpoint(os.Getenv("APPWRITE_FUNCTION_API_ENDPOINT")),
		appwrite.WithProject(os.Getenv("APPWRITE_FUNCTION_PROJECT_ID")),
		appwrite.WithKey(context.Req.Headers["x-appwrite-api-key"]),
		// appwrite.WithKey(os.Getenv("APPWRITE_API_KEY")),
	)

	var user *models.User
	var err error

	if userId, ok := context.Req.Headers["x-appwrite-user-id"]; ok {
		users := appwrite.NewUsers(client)
		user, err = users.Get(userId)

		if err != nil {
			context.Error(err)
			return context.Res.Empty()
		}
	}

	challenge := strings.ToLower(fmt.Sprintf("%s::%s", context.Req.Method, context.Req.Path))
	if match, _ := regexp.MatchString("^post::/new-tenant$", challenge); match {
		var tenant *models.Document
		tenant, err = handlers.CreateTenant(context, &client, user)
		if tenant != nil {
			return context.Res.Json(tenant, context.Res.WithStatusCode(200))
		}
	}

	if err != nil {
		context.Error(err)
		return context.Res.Send("Internal Server Error", context.Res.WithStatusCode(500))
	}

	return context.Res.Send("Service unavailable", context.Res.WithStatusCode(503))
}
