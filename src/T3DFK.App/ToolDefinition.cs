namespace T3DFK;

public sealed class ToolDefinition
{
    public string Id { get; set; } = "";
    public string Category { get; set; } = "Other";
    public string Name { get; set; } = "Unnamed Tool";
    public string Description { get; set; } = "";
    public string Path { get; set; } = "";
    public string Risk { get; set; } = "ReadOnly";
    public bool Interactive { get; set; }
    public string[] Args { get; set; } = Array.Empty<string>();
    public string Icon { get; set; } = "document";
}
