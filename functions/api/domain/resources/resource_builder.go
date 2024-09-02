package resources

import "strings"

const resourceDelimiter = "/"
const AnyResource = "*"

type ResourceType string

const (
	Resources    ResourceType = "resources"
	Tenants      ResourceType = "tenants"
	Institutions ResourceType = "institutions"
)

type ResourceBuilder struct {
	tokens []string
}

func (b *ResourceBuilder) Type(r ResourceType) *ResourceBuilder {
	b.tokens = append(b.tokens, string(r))
	return b
}

func (b *ResourceBuilder) Value(v string) *ResourceBuilder {
	b.tokens = append(b.tokens, v)
	return b
}

func (b *ResourceBuilder) Build() string {
	return strings.Join(b.tokens, resourceDelimiter)
}

func FromType(r ResourceType) *ResourceBuilder {
	return &ResourceBuilder{
		tokens: make([]string, 0),
	}
}

func FromValue(v string) *ResourceBuilder {
	return &ResourceBuilder{
		tokens: strings.Split(v, resourceDelimiter),
	}
}
