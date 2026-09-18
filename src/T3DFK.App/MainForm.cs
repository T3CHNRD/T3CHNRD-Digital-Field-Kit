using System.Diagnostics;

namespace T3DFK;

public sealed class MainForm : Form
{
    private readonly AppPaths _paths;
    private readonly List<ToolDefinition> _tools;
    private readonly StateStore _state;
    private readonly ToolRunner _runner;
    private readonly HashSet<string> _favorites;
    private readonly List<string> _recent;

    private readonly TableLayoutPanel _root = new();
    private readonly FlowLayoutPanel _sidebar = new();
    private readonly FlowLayoutPanel _cards = new();
    private readonly TextBox _search = new();
    private readonly Label _title = new();
    private readonly Label _subtitle = new();
    private readonly RichTextBox _console = new();
    private readonly Label _runName = new();
    private readonly Label _runState = new();
    private readonly Button _cancel = new();
    private readonly Button _openLog = new();
    private readonly Dictionary<string, Button> _tabs = new(StringComparer.OrdinalIgnoreCase);

    private string _view = "Favorites";
    private string _category = "All Tools";
    private string? _currentLog;

    private static readonly Color Navy = Color.FromArgb(7, 49, 73);
    private static readonly Color Dark = Color.FromArgb(3, 23, 32);
    private static readonly Color Paper = Color.FromArgb(239, 245, 249);
    private static readonly Color Lime = Color.FromArgb(154, 220, 37);

    public MainForm(AppPaths paths, List<ToolDefinition> tools)
    {
        _paths = paths;
        _tools = tools;
        _state = new StateStore(paths);
        _favorites = _state.LoadFavorites();
        _recent = _state.LoadRecent();
        _runner = new ToolRunner(paths);

        BuildUi();
        WireRunner();
        RenderSidebar();
        ShowView("Favorites");
    }

    private void BuildUi()
    {
        Text = "T3CHNRD Digital Field Kit";
        StartPosition = FormStartPosition.CenterScreen;
        MinimumSize = new Size(1050, 700);
        Size = new Size(1500, 900);
        BackColor = Paper;
        Font = new Font("Segoe UI", 10f);
        try { Icon = new Icon(Path.Combine(_paths.AssetsDirectory, "Toolkit.ico")); } catch { }

        _root.Dock = DockStyle.Fill;
        _root.RowCount = 5;
        _root.ColumnCount = 1;
        _root.RowStyles.Add(new RowStyle(SizeType.Absolute, 90));
        _root.RowStyles.Add(new RowStyle(SizeType.Absolute, 54));
        _root.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
        _root.RowStyles.Add(new RowStyle(SizeType.Absolute, 0));
        _root.RowStyles.Add(new RowStyle(SizeType.Absolute, 36));
        Controls.Add(_root);

        _root.Controls.Add(BuildHeader(), 0, 0);
        _root.Controls.Add(BuildNavigation(), 0, 1);
        _root.Controls.Add(BuildContent(), 0, 2);
        _root.Controls.Add(BuildRunCenter(), 0, 3);
        _root.Controls.Add(BuildStatusBar(), 0, 4);
    }

    private Control BuildHeader()
    {
        var panel = new Panel { Dock = DockStyle.Fill, BackColor = Color.FromArgb(12, 88, 126), Padding = new Padding(20, 10, 20, 8) };
        var grid = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, BackColor = Color.Transparent };
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 220));
        panel.Controls.Add(grid);

        var left = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, BackColor = Color.Transparent };
        left.Controls.Add(new Label { Text = "T3CHNRD Digital Field Kit", AutoSize = true, ForeColor = Color.White, Font = new Font("Segoe UI", 23f, FontStyle.Bold), Margin = new Padding(0, 0, 0, 0) });
        left.Controls.Add(new Label { Text = "Diagnose  |  Repair  |  Optimize  |  Deploy", AutoSize = true, ForeColor = Color.WhiteSmoke, Font = new Font("Segoe UI", 10f), Margin = new Padding(3, 0, 0, 0) });
        grid.Controls.Add(left, 0, 0);

        var right = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.TopDown, WrapContents = false, BackColor = Color.Transparent, Padding = new Padding(10, 7, 0, 0) };
        right.Controls.Add(new Label { Text = "WINDOWS", Width = 180, Height = 30, TextAlign = ContentAlignment.MiddleCenter, BackColor = Lime, ForeColor = Color.Black, Font = new Font("Segoe UI", 9f, FontStyle.Bold), Margin = new Padding(0, 0, 0, 3) });
        right.Controls.Add(new Label { Text = "v11 native rebuild", Width = 180, Height = 22, TextAlign = ContentAlignment.MiddleCenter, ForeColor = Color.WhiteSmoke, Margin = Padding.Empty });
        grid.Controls.Add(right, 1, 0);
        return panel;
    }

    private Control BuildNavigation()
    {
        var panel = new Panel { Dock = DockStyle.Fill, BackColor = Dark, Padding = new Padding(8, 6, 14, 6) };
        var grid = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, BackColor = Color.Transparent };
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        grid.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 320));
        panel.Controls.Add(grid);

        var tabs = new FlowLayoutPanel { Dock = DockStyle.Fill, FlowDirection = FlowDirection.LeftToRight, WrapContents = false, BackColor = Color.Transparent };
        foreach (var name in new[] { "Favorites", "Tools", "Recent", "Runbook", "Settings" })
        {
            var button = new Button
            {
                Text = name.ToUpperInvariant(),
                Width = 132,
                Height = 40,
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(28, 48, 58),
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 9.5f, FontStyle.Bold),
                Margin = new Padding(0, 0, 6, 0)
            };
            button.FlatAppearance.BorderColor = Color.FromArgb(94, 127, 142);
            var captured = name;
            button.Click += (_, _) => ShowView(captured);
            _tabs[name] = button;
            tabs.Controls.Add(button);
        }
        grid.Controls.Add(tabs, 0, 0);

        _search.Dock = DockStyle.Fill;
        _search.Margin = new Padding(0, 5, 0, 3);
        _search.Font = new Font("Segoe UI", 10.5f);
        _search.PlaceholderText = "Search tools...";
        _search.TextChanged += (_, _) => RenderCurrentView();
        grid.Controls.Add(_search, 1, 0);

        return panel;
    }

    private Control BuildContent()
    {
        var split = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 2, BackColor = Paper };
        split.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 210));
        split.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));

        var sidePanel = new Panel { Dock = DockStyle.Fill, BackColor = Color.FromArgb(14, 57, 82), Padding = new Padding(8, 12, 8, 8), AutoScroll = true };
        _sidebar.Dock = DockStyle.Top;
        _sidebar.AutoSize = true;
        _sidebar.FlowDirection = FlowDirection.TopDown;
        _sidebar.WrapContents = false;
        _sidebar.BackColor = Color.Transparent;
        sidePanel.Controls.Add(_sidebar);
        split.Controls.Add(sidePanel, 0, 0);

        var content = new TableLayoutPanel { Dock = DockStyle.Fill, RowCount = 2, ColumnCount = 1, BackColor = Paper, Padding = new Padding(18, 12, 18, 12) };
        content.RowStyles.Add(new RowStyle(SizeType.Absolute, 66));
        content.RowStyles.Add(new RowStyle(SizeType.Percent, 100));

        var pageHeader = new Panel { Dock = DockStyle.Fill, BackColor = Paper };
        _title.AutoSize = true;
        _title.Font = new Font("Segoe UI", 19f, FontStyle.Bold | FontStyle.Italic);
        _title.ForeColor = Color.FromArgb(13, 44, 72);
        _title.Location = new Point(0, 0);
        _subtitle.AutoSize = true;
        _subtitle.ForeColor = Color.FromArgb(76, 103, 125);
        _subtitle.Location = new Point(2, 38);
        pageHeader.Controls.Add(_title);
        pageHeader.Controls.Add(_subtitle);
        content.Controls.Add(pageHeader, 0, 0);

        _cards.Dock = DockStyle.Fill;
        _cards.AutoScroll = true;
        _cards.WrapContents = true;
        _cards.FlowDirection = FlowDirection.LeftToRight;
        _cards.BackColor = Paper;
        _cards.Resize += (_, _) => ResizeCards();
        content.Controls.Add(_cards, 0, 1);

        split.Controls.Add(content, 1, 0);
        return split;
    }

    private Control BuildRunCenter()
    {
        var panel = new Panel { Dock = DockStyle.Fill, BackColor = Color.FromArgb(4, 25, 34), Padding = new Padding(10) };
        var top = new Panel { Dock = DockStyle.Top, Height = 42, BackColor = Color.FromArgb(12, 65, 87) };

        _runName.Dock = DockStyle.Fill;
        _runName.ForeColor = Color.White;
        _runName.Font = new Font("Segoe UI", 15f, FontStyle.Bold);
        _runName.TextAlign = ContentAlignment.MiddleLeft;
        _runName.Padding = new Padding(8, 0, 0, 0);

        _runState.Dock = DockStyle.Right;
        _runState.Width = 175;
        _runState.ForeColor = Lime;
        _runState.Font = new Font("Segoe UI", 11f, FontStyle.Bold);
        _runState.TextAlign = ContentAlignment.MiddleCenter;

        _openLog.Text = "OPEN LOG";
        _openLog.Dock = DockStyle.Right;
        _openLog.Width = 90;
        _openLog.Click += (_, _) => OpenCurrentLog();

        _cancel.Text = "CANCEL";
        _cancel.Dock = DockStyle.Right;
        _cancel.Width = 80;
        _cancel.Enabled = false;
        _cancel.Click += (_, _) => _runner.Cancel();

        top.Controls.Add(_runName);
        top.Controls.Add(_runState);
        top.Controls.Add(_openLog);
        top.Controls.Add(_cancel);

        _console.Dock = DockStyle.Fill;
        _console.ReadOnly = true;
        _console.BackColor = Color.FromArgb(1, 17, 23);
        _console.ForeColor = Color.WhiteSmoke;
        _console.Font = new Font("Consolas", 9.5f);
        _console.BorderStyle = BorderStyle.FixedSingle;

        panel.Controls.Add(_console);
        panel.Controls.Add(top);
        _console.BringToFront();
        top.BringToFront();
        return panel;
    }

    private Control BuildStatusBar()
    {
        var panel = new Panel { Dock = DockStyle.Fill, BackColor = Navy };
        panel.Controls.Add(new Label { Text = "PORTABLE / INSTALLED", ForeColor = Color.WhiteSmoke, Dock = DockStyle.Right, Width = 180, TextAlign = ContentAlignment.MiddleRight, Padding = new Padding(0, 0, 10, 0) });
        panel.Controls.Add(new Label { Text = $"Computer: {Environment.MachineName}    User: {Environment.UserName}", ForeColor = Color.WhiteSmoke, Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleCenter });
        panel.Controls.Add(new Label { Text = "  READY", ForeColor = Color.White, Dock = DockStyle.Left, Width = 140, TextAlign = ContentAlignment.MiddleLeft, Font = new Font("Segoe UI", 11f, FontStyle.Bold) });
        return panel;
    }

    private void WireRunner()
    {
        _runner.Started += pid => Ui(() =>
        {
            _runState.Text = $"RUNNING {pid}";
            _runState.ForeColor = Lime;
            _cancel.Enabled = true;
        });
        _runner.Output += line => Ui(() => AppendConsole(line, Color.WhiteSmoke));
        _runner.Error += line => Ui(() => AppendConsole("ERROR: " + line, Color.Salmon));
        _runner.Completed += result => Ui(() =>
        {
            _currentLog = result.LogPath;
            _runState.Text = result.ExitCode == 0 ? "COMPLETE" : $"EXIT {result.ExitCode}";
            _runState.ForeColor = result.ExitCode == 0 ? Lime : Color.OrangeRed;
            _cancel.Enabled = false;
        });
    }

    private void ShowView(string view)
    {
        _view = view;
        foreach (var pair in _tabs)
        {
            var active = pair.Key.Equals(view, StringComparison.OrdinalIgnoreCase);
            pair.Value.BackColor = active ? Lime : Color.FromArgb(28, 48, 58);
            pair.Value.ForeColor = active ? Color.Black : Color.White;
        }

        _sidebar.Visible = view == "Tools";
        if (view == "Tools") _category = "All Tools";
        RenderCurrentView();
    }

    private void RenderCurrentView()
    {
        if (_view == "Runbook") { RenderRunbook(); return; }
        if (_view == "Settings") { RenderSettings(); return; }
        RenderCards();
    }

    private void RenderSidebar()
    {
        _sidebar.SuspendLayout();
        _sidebar.Controls.Clear();
        var categories = new[] { "All Tools" }
            .Concat(_tools.Select(t => t.Category).Distinct(StringComparer.OrdinalIgnoreCase).OrderBy(x => x));

        foreach (var category in categories)
        {
            var button = new Button
            {
                Text = category,
                Width = 188,
                Height = 40,
                FlatStyle = FlatStyle.Flat,
                BackColor = category == _category ? Color.FromArgb(48, 103, 71) : Color.Transparent,
                ForeColor = Color.White,
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(10, 0, 0, 0),
                Margin = new Padding(0, 0, 0, 4)
            };
            button.FlatAppearance.BorderSize = 0;
            var captured = category;
            button.Click += (_, _) =>
            {
                _category = captured;
                RenderSidebar();
                RenderCards();
            };
            _sidebar.Controls.Add(button);
        }
        _sidebar.ResumeLayout();
    }

    private void RenderCards()
    {
        _cards.SuspendLayout();
        _cards.Controls.Clear();

        IEnumerable<ToolDefinition> items = _tools;
        if (_view == "Favorites")
            items = items.Where(t => _favorites.Contains(t.Id));
        else if (_view == "Recent")
        {
            var order = _recent.Select((id, i) => (id, i)).ToDictionary(x => x.id, x => x.i, StringComparer.OrdinalIgnoreCase);
            items = items.Where(t => order.ContainsKey(t.Id)).OrderBy(t => order[t.Id]);
        }
        else if (_view == "Tools" && _category != "All Tools")
            items = items.Where(t => t.Category.Equals(_category, StringComparison.OrdinalIgnoreCase));

        var query = _search.Text.Trim();
        if (query.Length > 0)
            items = items.Where(t => $"{t.Name} {t.Description} {t.Category}".Contains(query, StringComparison.OrdinalIgnoreCase));

        _title.Text = _view == "Tools" ? _category : _view;
        _subtitle.Text = _view switch
        {
            "Favorites" => "Your favorite field tools.",
            "Recent" => "Recently launched tools.",
            _ => "Select a tool to diagnose, repair, optimize, secure, or deploy Windows systems."
        };

        foreach (var tool in items) _cards.Controls.Add(BuildCard(tool));

        if (_cards.Controls.Count == 0)
        {
            _cards.Controls.Add(new Label
            {
                Text = _view == "Favorites" ? "No favorites yet. Use the star on a tool card to add one." : "No matching tools.",
                AutoSize = true,
                ForeColor = Color.DimGray,
                Font = new Font("Segoe UI", 11f),
                Margin = new Padding(10, 20, 0, 0)
            });
        }

        ResizeCards();
        _cards.ResumeLayout();
    }

    private Control BuildCard(ToolDefinition tool)
    {
        var panel = new Panel
        {
            Width = 390,
            Height = 130,
            BackColor = Color.White,
            BorderStyle = BorderStyle.FixedSingle,
            Margin = new Padding(0, 0, 12, 12),
            Cursor = Cursors.Hand,
            Tag = tool
        };

        var name = new Label { Text = tool.Name, Font = new Font("Segoe UI", 11f, FontStyle.Bold), ForeColor = Color.FromArgb(11, 36, 69), Location = new Point(18, 18), Size = new Size(310, 25), AutoEllipsis = true };
        var desc = new Label { Text = tool.Description, ForeColor = Color.FromArgb(82, 109, 132), Location = new Point(18, 48), Size = new Size(340, 48), AutoEllipsis = true };
        var risk = new Label { Text = tool.Risk.ToUpperInvariant(), AutoSize = true, ForeColor = tool.Risk.Equals("ReadOnly", StringComparison.OrdinalIgnoreCase) ? Color.SlateGray : Color.DarkOrange, Font = new Font("Segoe UI", 7.5f, FontStyle.Bold), Location = new Point(18, 105) };
        var star = new Button { Text = _favorites.Contains(tool.Id) ? "★" : "☆", Width = 34, Height = 30, Location = new Point(348, 4), Anchor = AnchorStyles.Top | AnchorStyles.Right, FlatStyle = FlatStyle.Flat, BackColor = Color.White, ForeColor = Color.Goldenrod };
        star.FlatAppearance.BorderSize = 0;
        star.Click += (_, _) => ToggleFavorite(tool.Id);

        panel.Controls.Add(name);
        panel.Controls.Add(desc);
        panel.Controls.Add(risk);
        panel.Controls.Add(star);

        panel.Click += (_, _) => LaunchTool(tool);
        name.Click += (_, _) => LaunchTool(tool);
        desc.Click += (_, _) => LaunchTool(tool);
        risk.Click += (_, _) => LaunchTool(tool);
        return panel;
    }

    private async void LaunchTool(ToolDefinition tool)
    {
        if (_runner.IsRunning)
        {
            MessageBox.Show(this, "Another tool is already running. Finish or cancel it first.", "T3CHNRD Digital Field Kit", MessageBoxButtons.OK, MessageBoxIcon.Information);
            return;
        }

        if (!tool.Risk.Equals("ReadOnly", StringComparison.OrdinalIgnoreCase))
        {
            var message = tool.Risk.Equals("HighRisk", StringComparison.OrdinalIgnoreCase)
                ? "This tool can make significant system changes. Continue?"
                : "This tool can change system configuration. Continue?";
            if (MessageBox.Show(this, message, tool.Name, MessageBoxButtons.YesNo, MessageBoxIcon.Warning) != DialogResult.Yes)
                return;
        }

        _state.AddRecent(tool.Id);
        _recent.Clear();
        _recent.AddRange(_state.LoadRecent());

        if (tool.Interactive)
        {
            try { await _runner.RunAsync(tool); }
            catch (Exception ex) { MessageBox.Show(this, ex.Message, "Tool launch failed", MessageBoxButtons.OK, MessageBoxIcon.Error); }
            return;
        }

        _root.RowStyles[3].Height = 240;
        _runName.Text = tool.Name;
        _runState.Text = "STARTING";
        _runState.ForeColor = Lime;
        _console.Clear();
        _console.AppendText($"Starting {tool.Name}...{Environment.NewLine}");
        _cancel.Enabled = false;
        _currentLog = null;

        try
        {
            await _runner.RunAsync(tool);
        }
        catch (OperationCanceledException)
        {
            AppendConsole("Cancelled.", Color.Gold);
            _runState.Text = "CANCELLED";
        }
        catch (Exception ex)
        {
            AppendConsole(ex.ToString(), Color.Salmon);
            _runState.Text = "LAUNCH FAILED";
            _runState.ForeColor = Color.OrangeRed;
            _cancel.Enabled = false;
        }
    }

    private void RenderRunbook()
    {
        _sidebar.Visible = false;
        _cards.Controls.Clear();
        _title.Text = "Runbook";
        _subtitle.Text = "Shared field documentation. Full wiki integration follows Windows stabilization.";

        var panel = new Panel { Width = Math.Max(700, _cards.ClientSize.Width - 40), Height = 200, BackColor = Color.White, BorderStyle = BorderStyle.FixedSingle };
        panel.Controls.Add(new Label { Text = "The v11 rebuild keeps the Runbook beside the portable app. Full browsing, document import, editing, indexing, and AI retrieval are Phase 2.", Location = new Point(24, 24), Size = new Size(650, 70), ForeColor = Color.FromArgb(30, 60, 82) });
        var open = new Button { Text = "OPEN RUNBOOK FOLDER", Location = new Point(24, 120), Size = new Size(210, 40), BackColor = Lime };
        open.Click += (_, _) => Process.Start(new ProcessStartInfo("explorer.exe", $""{_paths.RunbookDirectory}"") { UseShellExecute = true });
        panel.Controls.Add(open);
        _cards.Controls.Add(panel);
    }

    private void RenderSettings()
    {
        _sidebar.Visible = false;
        _cards.Controls.Clear();
        _title.Text = "Settings";
        _subtitle.Text = "Application and platform status.";

        _cards.Controls.Add(new Label
        {
            Width = 800,
            Height = 250,
            BackColor = Color.White,
            BorderStyle = BorderStyle.FixedSingle,
            Padding = new Padding(20),
            Font = new Font("Segoe UI", 10.5f),
            Text = $"T3CHNRD Digital Field Kit v11\r\n\r\nPlatform: Windows\r\nArchitecture: {System.Runtime.InteropServices.RuntimeInformation.OSArchitecture}\r\nPortable root: {_paths.Root}\r\nPowerShell: {ToolRunner.ResolvePowerShell()}\r\nTools loaded: {_tools.Count}\r\n\r\nmacOS Intel and Apple Silicon support remains on the project TODO after Windows stabilization and Runbook integration."
        });
    }

    private void ToggleFavorite(string id)
    {
        if (!_favorites.Add(id)) _favorites.Remove(id);
        _state.SaveFavorites(_favorites);
        RenderCurrentView();
    }

    private void ResizeCards()
    {
        var columns = _cards.ClientSize.Width >= 1180 ? 3 : _cards.ClientSize.Width >= 760 ? 2 : 1;
        var width = Math.Max(340, (_cards.ClientSize.Width - 40) / columns);
        foreach (Control control in _cards.Controls)
            if (control.Tag is ToolDefinition) control.Width = width;
    }

    private void OpenCurrentLog()
    {
        if (_currentLog != null && File.Exists(_currentLog))
            Process.Start(new ProcessStartInfo("notepad.exe", $""{_currentLog}"") { UseShellExecute = true });
        else
            MessageBox.Show(this, "No completed tool log is available yet.", "T3CHNRD Digital Field Kit", MessageBoxButtons.OK, MessageBoxIcon.Information);
    }

    private void AppendConsole(string text, Color color)
    {
        _console.SelectionStart = _console.TextLength;
        _console.SelectionColor = color;
        _console.AppendText(text + Environment.NewLine);
        _console.SelectionColor = _console.ForeColor;
        _console.ScrollToCaret();
    }

    private void Ui(Action action)
    {
        if (IsDisposed) return;
        if (InvokeRequired) BeginInvoke(action);
        else action();
    }
}
