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

string appName = "CairoWindow";
string description = "A simple win32 window with Cairo drawing";
HINSTANCE hinst;

import cairo.c.cairo;
import cairo.cairo;
import cairo.win32;

import voxtrac.tree;

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

    while (GetMessage(&msg, null, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);

        //writeln(Clock.currTime);
    }

    return msg.wParam;
}

// void roundedRectangle(Context ctx, int x, int y, int w, int h, int radius_x = 5, int radius_y = 5) {
//     enum ARC_TO_BEZIER = 0.55228475;

//     if (radius_x > w - radius_x)
//         radius_x = w / 2;

//     if (radius_y > h - radius_y)
//         radius_y = h / 2;

//     // approximate (quite close) the arc using a bezier curve
//     auto c1 = ARC_TO_BEZIER * radius_x;
//     auto c2 = ARC_TO_BEZIER * radius_y;

//     ctx.newPath();
//     ctx.moveTo(x + radius_x, y);
//     ctx.relLineTo(w - 2 * radius_x, 0.0);
//     ctx.relCurveTo(c1, 0.0, radius_x, c2, radius_x, radius_y);
//     ctx.relLineTo(0, h - 2 * radius_y);
//     ctx.relCurveTo(0.0, c2, c1 - radius_x, radius_y, -radius_x, radius_y);
//     ctx.relLineTo(-w + 2 * radius_x, 0);
//     ctx.relCurveTo(-c1, 0, -radius_x, -c2, -radius_x, -radius_y);
//     ctx.relLineTo(0, -h + 2 * radius_y);
//     ctx.relCurveTo(0.0, -c2, radius_x - c1, -radius_y, radius_x, -radius_y);
//     ctx.closePath();
// }

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
float objX = 0, objY = 0;

void GameLoop(Duration dt) {
    //objX += 10f * dt.total!"usecs" / 1000000.0;
    //objY += 10f * dt.total!"usecs" / 1000000.0;

    //append("test.txt", format("%f %f\r\n", objX, objY));
}

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
                
                //append("test.txt", Clock.currTime.toString() ~ "\r\n");
                GameLoop(dt);                
                InvalidateRect(hwnd, cast(const(RECT)*)0, 0);
                //return OnPaint(hwnd, message, wParam, lParam);
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

        _buffer = CreateCompatibleDC(hdc);
        hBitmap = CreateCompatibleBitmap(hdc, width, height);
        hOldBitmap = SelectObject(_buffer, hBitmap);

        
        //for(int i = top; i < bottom; ++i)
        //    for(int j = left; j < bottom; ++j)
        //        SetPixelV(_buffer, j, i, core.sys.windows.wingdi.RGB(0,255,0));
        //SetPixel(_buffer, roundTo!int(objX), roundTo!int(objY), core.sys.windows.wingdi.RGB(255,255,255));
        

        auto surf = new Win32Surface(_buffer);      
        auto image = new ImageSurface(Format.CAIRO_FORMAT_RGB24, width, height);
        auto dataPtr = image.getData();

        auto stride = formatStrideForWidth(Format.CAIRO_FORMAT_RGB24, width);        

        //foreach(i; 0..100) 
        //    dataPtr[i] = 255;
        //image.flush();
        static ubyte color = 0;
        color += 3;

        foreach(y; 0..height) 
            foreach(x; 0..width) {                
                //dataPtr[y*stride + x * 4] = 0;
                dataPtr[y*stride + x * 4 + 2] = color;
                //dataPtr[y*stride + x * 4 + 2] = 0;
            }

        //append("test.txt", format("%d %d\r\n", height, width));
        

        image.flush();
            
        
        auto ctx = Context(surf);
        ctx.setSourceSurface(image, 0, 0);
        ctx.paint();

        image.dispose();

        // ctx.setSourceRGB(1, 1, 1);
        // ctx.paint();

        // roundedRectangle(ctx, 50, 50, 250, 250, 10, 10);

        // auto clr = RGB(0.9411764705882353, 0.996078431372549, 0.9137254901960784);
        // //auto clr = RGB(0.5,0,0);
        // ctx.setSourceRGB(clr);
        // ctx.fillPreserve();

        // clr = RGB(0.7019607843137254, 1.0, 0.5529411764705883);
        // ctx.setSourceRGB(clr);
        // ctx.stroke();

        // ctx.setSourceRGB(0, 0, 0);
        // ctx.selectFontFace("Arial", FontSlant.CAIRO_FONT_SLANT_NORMAL,
        //         FontWeight.CAIRO_FONT_WEIGHT_NORMAL);
        // ctx.setFontSize(10.0);
        // auto txt = "Cairo is the greatest thing!";
        // ctx.moveTo(5.0, 10.0);
        // ctx.showText(txt);

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
