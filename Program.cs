using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

[assembly: AssemblyTitle("Выключение Windows")]
[assembly: AssemblyDescription("Выключение компьютера через 30 секунд")]
[assembly: AssemblyVersion("1.0.0.0")]

internal static class Program
{
    [STAThread]
    private static void Main()
    {
        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.SystemDirectory, "shutdown.exe"),
                Arguments = "-s -t 30 -c \"Компьютер выключится через 30 секунд\"",
                UseShellExecute = false,
                CreateNoWindow = true
            };
            using (var process = Process.Start(startInfo))
            {
                process.WaitForExit();
                if (process.ExitCode != 0)
                {
                    MessageBox.Show("Windows не удалось запланировать выключение. Код ошибки: " + process.ExitCode,
                        "Выключение Windows", MessageBoxButtons.OK, MessageBoxIcon.Error);
                }
            }
        }
        catch (Exception exception)
        {
            MessageBox.Show(exception.Message, "Выключение Windows", MessageBoxButtons.OK, MessageBoxIcon.Error);
        }
    }
}
