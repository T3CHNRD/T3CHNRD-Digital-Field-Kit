using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

internal static class WindowHost
{
    private const uint WM_SETICON = 0x0080;
    private const int ICON_SMALL = 0;
    private const int ICON_BIG = 1;
    private const uint IMAGE_ICON = 1;
    private const uint LR_LOADFROMFILE = 0x0010;
    private const uint LR_DEFAULTSIZE = 0x0040;

    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr LoadImage(IntPtr hInst, string name, uint type, int cx, int cy, uint fuLoad);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    private static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);

    [STAThread]
    private static int Main(string[] args)
    {
        try
        {
            if (args.Length < 2) return 2;
            string hta = Path.GetFullPath(args[0]);
            string icon = Path.GetFullPath(args[1]);
            if (!File.Exists(hta)) return 3;

            string mshta = Path.Combine(Environment.SystemDirectory, "mshta.exe");
            if (!File.Exists(mshta)) mshta = "mshta.exe";

            var psi = new ProcessStartInfo
            {
                FileName = mshta,
                Arguments = "\"" + hta + "\"",
                WorkingDirectory = Path.GetDirectoryName(hta),
                UseShellExecute = false,
                CreateNoWindow = false
            };

            using (var process = Process.Start(psi))
            {
                if (process == null) return 4;

                IntPtr hwnd = IntPtr.Zero;
                for (int i = 0; i < 120 && !process.HasExited; i++)
                {
                    Thread.Sleep(100);
                    process.Refresh();
                    hwnd = process.MainWindowHandle;
                    if (hwnd != IntPtr.Zero) break;
                }

                if (hwnd != IntPtr.Zero && File.Exists(icon))
                {
                    IntPtr big = LoadImage(IntPtr.Zero, icon, IMAGE_ICON, 32, 32, LR_LOADFROMFILE | LR_DEFAULTSIZE);
                    IntPtr small = LoadImage(IntPtr.Zero, icon, IMAGE_ICON, 16, 16, LR_LOADFROMFILE | LR_DEFAULTSIZE);
                    if (big != IntPtr.Zero) SendMessage(hwnd, WM_SETICON, new IntPtr(ICON_BIG), big);
                    if (small != IntPtr.Zero) SendMessage(hwnd, WM_SETICON, new IntPtr(ICON_SMALL), small);
                }

                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception ex)
        {
            try
            {
                File.AppendAllText(Path.Combine(Path.GetTempPath(), "T3DFK-WindowHost.log"), DateTime.Now + " " + ex + Environment.NewLine);
            }
            catch { }
            return 1;
        }
    }
}
