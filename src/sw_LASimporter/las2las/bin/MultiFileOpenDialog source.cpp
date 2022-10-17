#include <windows.h>
#include <shobjidl.h> 
#include <stdio.h> 
#include <iostream>
using namespace std;


int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PWSTR pCmdLine, int nCmdShow)
{
    COMDLG_FILTERSPEC ComDlgFS[2] = { {L"LAZ/LAS", L"*.laz;*.las"}, {L"All Files",L"*.*"} };

    HRESULT hr = CoInitializeEx(NULL, COINIT_APARTMENTTHREADED |
        COINIT_DISABLE_OLE1DDE);
    if (SUCCEEDED(hr))
    {
        IFileOpenDialog* pFileOpen;

        // Create the FileOpenDialog object.
        hr = CoCreateInstance(CLSID_FileOpenDialog, NULL, CLSCTX_ALL,
            IID_IFileOpenDialog, reinterpret_cast<void**>(&pFileOpen));

        if (SUCCEEDED(hr))
        {
            // Set options for a filesystem picker dialog.
            FILEOPENDIALOGOPTIONS opt{};
            pFileOpen->GetOptions(&opt);
            pFileOpen->SetOptions(opt | FOS_ALLOWMULTISELECT);
            pFileOpen->SetFileTypes(2, ComDlgFS);

            // Show the Open dialog box.
            hr = pFileOpen->Show(NULL);

            // Get the file names from the dialog box.
            if (SUCCEEDED(hr))
            {
                IShellItemArray* pItemArray;
                hr = pFileOpen->GetResults(&pItemArray);

                if (SUCCEEDED(hr))
                {
                    DWORD dwItemCount = 0;

                    hr = pItemArray->GetCount(&dwItemCount);
                    if (SUCCEEDED(hr))
                    {
                        IShellItem* pItem;
                        PWSTR pszFilePath;

                        for (DWORD dwItem = 0; dwItem < dwItemCount; dwItem++)
                        {
                            hr = pItemArray->GetItemAt(dwItem, &pItem);
                            if (SUCCEEDED(hr))
                            {
                                hr = pItem->GetDisplayName(SIGDN_FILESYSPATH, &pszFilePath);

                                // 
                                if (SUCCEEDED(hr))
                                {
                                    //MessageBoxW(NULL, pszFilePath, L"File Path", MB_OK);
                                    // ALSO fprintf( stderr, "my %s has %d chars\n", "string format", 30);
                                    wcerr << pszFilePath << "\n";
                                    CoTaskMemFree(pszFilePath);
                                }

                            }
                            pItem->Release();
                        }
                    }
                    pItemArray->Release();
                }
            }
            pFileOpen->Release();
        }
        CoUninitialize();
    }
    return 0;
}
