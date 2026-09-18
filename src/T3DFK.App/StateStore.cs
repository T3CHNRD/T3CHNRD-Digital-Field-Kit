using System.Text.Json;

namespace T3DFK;

public sealed class StateStore
{
    private readonly AppPaths _paths;
    private static readonly JsonSerializerOptions JsonOptions = new() { WriteIndented = true };
    public StateStore(AppPaths paths) => _paths = paths;

    public HashSet<string> LoadFavorites() => LoadSet(_paths.FavoritesFile);
    public void SaveFavorites(IEnumerable<string> ids) => Save(_paths.FavoritesFile, ids.Distinct().ToArray());
    public List<string> LoadRecent() => LoadList(_paths.RecentFile);
    public void AddRecent(string id)
    {
        var items = LoadRecent();
        items.RemoveAll(x => string.Equals(x, id, StringComparison.OrdinalIgnoreCase));
        items.Insert(0, id);
        if (items.Count > 30) items.RemoveRange(30, items.Count - 30);
        Save(_paths.RecentFile, items);
    }

    private static HashSet<string> LoadSet(string file) => new(LoadList(file), StringComparer.OrdinalIgnoreCase);
    private static List<string> LoadList(string file)
    {
        try
        {
            if (!File.Exists(file)) return new List<string>();
            return JsonSerializer.Deserialize<List<string>>(File.ReadAllText(file)) ?? new List<string>();
        }
        catch { return new List<string>(); }
    }
    private static void Save<T>(string file, T value)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(file)!);
        File.WriteAllText(file, JsonSerializer.Serialize(value, JsonOptions));
    }
}
