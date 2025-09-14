// get_disk_info.cpp
// Compile with: cl /EHsc get_disk_info.cpp  (Visual Studio Developer Command Prompt)
// Or with mingw: g++ -std=c++17 -Wall -O2 -o get_disk_info.exe get_disk_info.cpp

#include <windows.h>
#include <winioctl.h>
#include <iostream>
#include <vector>
#include <string>

std::string read_string_from_buffer(const std::vector<BYTE>& buf, DWORD offset)
{
    if (offset == 0 || offset >= buf.size())
        return std::string();
    const char* base = reinterpret_cast<const char*>(buf.data() + offset);
    // Ensure null-terminated safety
    size_t maxlen = buf.size() - offset;
    size_t len = strnlen_s(base, maxlen);
    return std::string(base, len);
}

int wmain(int argc, wchar_t** argv)
{
    std::wstring physical = L"\\\\.\\PhysicalDrive0";
    if (argc >= 2) {
        physical = argv[1];
    }

    std::wcout << L"Opening: " << physical << L"\n(Requires Administrator privileges)\n\n";

    HANDLE h = CreateFileW(physical.c_str(),
                           GENERIC_READ | GENERIC_WRITE,
                           FILE_SHARE_READ | FILE_SHARE_WRITE,
                           nullptr,
                           OPEN_EXISTING,
                           0,
                           nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        std::wcerr << L"CreateFile failed. Error: " << GetLastError() << L"\n";
        return 1;
    }

    STORAGE_PROPERTY_QUERY query;
    ZeroMemory(&query, sizeof(query));
    query.PropertyId = StorageDeviceProperty;
    query.QueryType = PropertyStandardQuery;

    const DWORD bufSize = 4096; // buffer bigger to be safe
    std::vector<BYTE> buffer(bufSize);
    DWORD bytesReturned = 0;

    BOOL ok = DeviceIoControl(h,
                              IOCTL_STORAGE_QUERY_PROPERTY,
                              &query, sizeof(query),
                              buffer.data(), (DWORD)buffer.size(),
                              &bytesReturned,
                              nullptr);
    if (!ok) {
        std::wcerr << L"DeviceIoControl failed. Error: " << GetLastError() << L"\n";
        CloseHandle(h);
        return 1;
    }

    if (bytesReturned == 0) {
        std::wcerr << L"No data returned from DeviceIoControl\n";
        CloseHandle(h);
        return 1;
    }

    STORAGE_DEVICE_DESCRIPTOR* desc = reinterpret_cast<STORAGE_DEVICE_DESCRIPTOR*>(buffer.data());

    std::string vendor = read_string_from_buffer(buffer, desc->VendorIdOffset);
    std::string product = read_string_from_buffer(buffer, desc->ProductIdOffset);
    std::string revision = read_string_from_buffer(buffer, desc->ProductRevisionOffset);
    std::string serial = read_string_from_buffer(buffer, desc->SerialNumberOffset);

    std::cout << "Bytes returned: " << bytesReturned << "\n";
    std::cout << "VendorId:  " << (vendor.empty() ? "<N/A>" : vendor) << "\n";
    std::cout << "ProductId: " << (product.empty() ? "<N/A>" : product) << "\n";
    std::cout << "Revision:  " << (revision.empty() ? "<N/A>" : revision) << "\n";
    std::cout << "Serial:    " << (serial.empty() ? "<N/A>" : serial) << "\n";

    CloseHandle(h);
    return 0;
}



int APIENTRY WinMain(HINSTANCE, HINSTANCE, LPSTR, int) {
    AllocConsole();
    FILE* fp;
    freopen_s(&fp, "CONOUT$", "w", stdout);
    freopen_s(&fp, "CONOUT$", "w", stderr);

    // zavoláme tvoje wmain
    int argc = 0;
    LPWSTR* argvW = CommandLineToArgvW(GetCommandLineW(), &argc);
    int ret = wmain(argc, argvW);
    LocalFree(argvW);

    system("pause"); // aby se hned nezavřelo
    return ret;
}