import core.runtime;
import std.utf;
import std.stdio;
import std.datetime;
import std.file;
import std.math;
import std.algorithm;
import std.conv;
import std.typecons;
import std.format;
import core.time;

//Needed for DMD
//pragma(lib, "gdi32.lib");
//pragma(lib, "user32.lib");

//NOTE: cairo should not depend on windows-headers package either (remove the dependency from its dub.json)

import core.sys.windows.windef;
import core.sys.windows.winuser;
import core.sys.windows.wingdi;

string appName = "Voxtrac";
string description = "Voxtrac";
HINSTANCE hinst;

import cairo.c.cairo;
import cairo.cairo;
import cairo.win32;

import voxtrac.tree;
import voxtrac.app;

alias RGB = cairo.cairo.RGB; // conflicts with win32.wingdi.RGB

extern (Windows) ulong WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
        LPSTR lpCmdLine, int iCmdShow) {
    ulong result;

    try {
        Runtime.initialize();
        result = myWinMain(hInstance, hPrevInstance, lpCmdLine, iCmdShow);
        Runtime.terminate();
    }
    catch (Throwable o) {
        MessageBox(null, o.toString().toUTF16z, "Error", MB_OK | MB_ICONEXCLAMATION);
        result = 0;
    }

    return result;
}

ulong myWinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, LPSTR lpCmdLine, int iCmdShow) {
    hinst = hInstance;
    HACCEL hAccel;
    HWND hwnd;
    MSG msg;
    WNDCLASS wndclass;

    wndclass.style = CS_HREDRAW | CS_VREDRAW;
    wndclass.lpfnWndProc = &WndProc;
    wndclass.cbClsExtra = 0;
    wndclass.cbWndExtra = 0;
    wndclass.hInstance = hInstance;
    wndclass.hIcon = LoadIcon(null, IDI_APPLICATION);
    wndclass.hCursor = LoadCursor(null, IDC_ARROW);
    wndclass.hbrBackground = cast(HBRUSH) GetStockObject(WHITE_BRUSH);
    wndclass.lpszMenuName = appName.toUTF16z;
    wndclass.lpszClassName = appName.toUTF16z;

    if (!RegisterClass(&wndclass)) {
        MessageBox(null, "This program requires Windows NT!", appName.toUTF16z, MB_ICONERROR);
        return 0;
    }

    hwnd = CreateWindow(appName.toUTF16z, // window class name
            description.toUTF16z, // window caption
            WS_OVERLAPPEDWINDOW, // window style
            400, // initial x position
            400, // initial y position
            400, // initial x size
            400, // initial y size
            null, // parent window handle
            null, // window menu handle
            hInstance, // program instance handle
            null); // creation parameters

    ShowWindow(hwnd, iCmdShow);
    UpdateWindow(hwnd);

    t0 = Clock.currTime;
    SetTimer(hwnd, 0, 1000 / 60, null);   

    appStart();  

    while (GetMessage(&msg, null, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);

        //writeln(Clock.currTime);
    }

    return msg.wParam;
}

extern (Windows) LRESULT WndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow {
    switch (message) {
    case WM_CREATE: {
            window = new Window(hwnd);
            return 0;
        }

    default:
    }

    if (window)
        return window.process(hwnd, message, wParam, lParam);
    else
        return DefWindowProc(hwnd, message, wParam, lParam);
}

SysTime t0;
Window window;

class Window {
    int x, y;
    HWND hwnd;
    HDC hdc;
    PAINTSTRUCT ps;
    RECT rc;
    HDC _buffer;
    HBITMAP hBitmap;
    HBITMAP hOldBitmap;

    this(HWND hwnd) nothrow {
        this.hwnd = hwnd;
    }

    LRESULT process(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) nothrow {
        try {
            switch (message) {
            case WM_DESTROY:
                return OnDestroy(hwnd, message, wParam, lParam);

            case WM_PAINT:
                return OnPaint(hwnd, message, wParam, lParam);

            case WM_ERASEBKGND:
                return 0;

            case WM_TIMER:
                auto t1 = Clock.currTime;
                auto dt = t1 - t0;
                t0 = t1;                                
                
                appLoop(dt);
                InvalidateRect(hwnd, cast(const(RECT)*)0, 0);                
                return 0;

            default:
            }
        }
        catch (Throwable e) {

        }

        return DefWindowProc(hwnd, message, wParam, lParam);
    }

    auto OnPaint(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {        
        hdc = BeginPaint(hwnd, &ps);
        GetClientRect(hwnd, &rc);

        auto left = rc.left;
        auto top = rc.top;
        auto right = rc.right;
        auto bottom = rc.bottom;

        auto width = right - left;
        auto height = bottom - top;
        x = left;
        y = top;

        //TODO: create all of this once, not once per frame!
        _buffer = CreateCompatibleDC(hdc);
        hBitmap = CreateCompatibleBitmap(hdc, width, height);
        hOldBitmap = SelectObject(_buffer, hBitmap);        

        auto surf = new Win32Surface(_buffer);      
        auto image = new ImageSurface(Format.CAIRO_FORMAT_RGB24, width, height);
        auto dataPtr = image.getData();

        auto stride = formatStrideForWidth(Format.CAIRO_FORMAT_RGB24, width);     

        Canvas canv = Canvas(cast(Color*)dataPtr, stride/4, width, height);
        appDraw(canv);       

        image.flush();
            
        
        auto ctx = Context(surf);
        ctx.setSourceSurface(image, 0, 0);
        ctx.paint();

        image.dispose();        

        surf.finish();
        BitBlt(hdc, 0, 0, width, height, _buffer, x, y, SRCCOPY);

        SelectObject(_buffer, hOldBitmap);
        DeleteObject(hBitmap);
        DeleteDC(_buffer);

        EndPaint(hwnd, &ps);
        return 0;
    }

    auto OnDestroy(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam) {
        PostQuitMessage(0);
        return 0;
    }
}
