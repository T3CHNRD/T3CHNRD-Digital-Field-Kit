namespace T3DFK;

public sealed record ToolDefinition(
    string Id,
    string Name,
    string Category,
    string Description,
    FieldPlatform Platform,
    string Command,
    string Arguments,
    bool RequiresAdmin = false,
    bool Interactive = false);
