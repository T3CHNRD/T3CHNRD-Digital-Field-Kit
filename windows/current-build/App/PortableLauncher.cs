using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

internal static class Program
{
    [STAThread]
    private static int Main()
    {
        try
        {
            string root = AppDomain.CurrentDomain.BaseDirectory;
            string launcher = Path.Combine(root, "OPEN-ME-GUI.vbs");
            if (!File.Exists(launcher))
            {
                MessageBox.Show("OPEN-ME-GUI.vbs is missing. Extract the complete toolkit package.", "T3CHNRD Digital Field Kit", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return 2;
            }
            string wscript = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "System32", "wscript.exe");
            var psi = new ProcessStartInfo
            {
                FileName = wscript,
                Arguments = "\"" + launcher + "\"",
                WorkingDirectory = root,
                UseShellExecute = true
            };
            Process.Start(psi);
            return 0;
        }
        catch (Exception ex)
        {
            MessageBox.Show(ex.Message, "T3CHNRD Digital Field Kit", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
