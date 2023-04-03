#include <Windows.h>
#include <stdio.h>
#include "structs.h"
#include <map>
#include <string>

/*
	All credits to 
	- https://github.com/am0nsec/HellsGate/tree/master/HellsGate
	- https://github.com/Crummie5/FreshyCalls
	- https://alice.climent-pommeret.red/posts/direct-syscalls-hells-halos-syswhispers2/
*/

int main(void) {
	// PEB and NTDLL from LDR_DATA
	PPEB peb = (PPEB)__readgsqword(0x60); // "PEB at the GS register with a 96byte (0x60) offset" 
	printf("[+] PEB address: %p\n", peb);

	PLDR_MODULE pLoadModule;
	pLoadModule = (PLDR_MODULE)((PBYTE)peb->LoaderData->InMemoryOrderModuleList.Flink->Flink - 0x10);
	printf("[+] Loaded module: %ws\r\n", pLoadModule->FullDllName.Buffer);

	PBYTE ImageBase;
	PIMAGE_DOS_HEADER Dos = NULL;
	PIMAGE_NT_HEADERS Nt = NULL;
	PIMAGE_FILE_HEADER File = NULL;
	PIMAGE_OPTIONAL_HEADER Optional = NULL;
	PIMAGE_EXPORT_DIRECTORY ExportTable = NULL;

	// Dos, NT, File, Optional, Export table 
	ImageBase = (PBYTE)pLoadModule->BaseAddress;
	Dos = (PIMAGE_DOS_HEADER)ImageBase;
	if (Dos->e_magic != IMAGE_DOS_SIGNATURE) {
		printf("[-] DOS signature not found\n");
	}
	Nt = (PIMAGE_NT_HEADERS)((PBYTE)Dos + Dos->e_lfanew);
	File = (PIMAGE_FILE_HEADER)(ImageBase + (Dos->e_lfanew + sizeof(DWORD))); // e_lfanew + 4 bytes (sizeof(DWORD))
	Optional = (PIMAGE_OPTIONAL_HEADER)((PBYTE)File + sizeof(IMAGE_FILE_HEADER)); // file + sizeof(IMAGE_FILE_HEADER) (20bytes)
	ExportTable = (PIMAGE_EXPORT_DIRECTORY)(ImageBase + Optional->DataDirectory[0].VirtualAddress); // DataDirectory + first ordinal in array

	printf("[+] Dos signature: 0x%X\n", Dos->e_magic);
	printf("[+] Nt header addr: %p\n", Nt);
	printf("[+] File header addr: %p\n", File);
	printf("[+] Optional header addr: %p\n", Optional);
	printf("[+] Export Directory addr: %p\n", ExportTable);

	// Various export tables from ntdll 
	DWORD* FuncAddr_Table = (DWORD*)(ImageBase + ExportTable->AddressOfFunctions);
	DWORD* Names_Table = (DWORD*)(ImageBase + ExportTable->AddressOfNames);
	WORD* Names_Ordinal_Table = (WORD*)(ImageBase + ExportTable->AddressOfNameOrdinals);
	DWORD numOfNtNames = 0;

	// Print out the function names, ordinals, and memory addresses
	//for (int i = 0; i < ExportTable->NumberOfNames; i++) {

	//	DWORD nameOffset = Names_Table[i];
	//	char* funcName = (char*)(ImageBase + nameOffset);

	//	if (strncmp(funcName, "Nt", 2) == 0 && strncmp(funcName, "Ntdll", 5) != 0) {
	//		printf("[+] Function Name: %s\n", funcName);

	//		WORD ordinal = Names_Ordinal_Table[i];
	//		printf("[+] Ordinal Value: %d\n", ordinal);

	//		DWORD functionAddr = (DWORD)(ImageBase + FuncAddr_Table[ordinal]);
	//		printf("[+] Function Address: 0x%p\n", (void*)functionAddr);

	//		numOfNtNames++;
	//	}
	//}

	// cpp map orders the key sequentially by default - til. 
	// Map to store ntapi functionaddr:functionname
	std::map<DWORD, std::string> funcAddrNameMap;
	std::map<DWORD, std::string> funcNameSortedMap;
	std::map<std::string, DWORD> funcNameSyscallMap;

	// Populate each maps with funcAddr, funcName
	for (int i = 0; i < ExportTable->NumberOfNames; i++) {
		DWORD nameOffset = Names_Table[i];
		WORD ordinal = Names_Ordinal_Table[i];
		DWORD functionAddr = (DWORD)(ImageBase + FuncAddr_Table[ordinal]);
		char* funcName = (char*)(ImageBase + nameOffset);

		if (strncmp(funcName, "Nt", 2) == 0 && strncmp(funcName, "Ntdll", 5) != 0 &&
			strncmp(funcName, "NtGetTickCount", 14) != 0) {
			printf("[+] funcName: %s\n", funcName);
			funcAddrNameMap[functionAddr] = funcName;
		}
	}

	// Populate funcNameSyscallMap with funcName sorted based on the address (lowest to highest) from funcAddrNameMap.
	for (auto& kv : funcAddrNameMap) {
		funcNameSortedMap[kv.first] = kv.second;
	}

	DWORD syscallNumber = 0;
	for (auto& kv : funcNameSortedMap) {
		funcNameSyscallMap[kv.second] = syscallNumber;
		syscallNumber++;
	}

	// Print stuff 
	for (auto& kv : funcAddrNameMap) {
		printf("[+] Function Address: 0x%p, Function Name: %s\n", (void*)kv.first, kv.second.c_str());
	}

	printf("[+] Function Name:                                Syscall Number:\n");
	for (auto& kv : funcNameSyscallMap) {
		printf("[+] %-*s %d\n", 50, kv.first.c_str(), kv.second);
	}
}