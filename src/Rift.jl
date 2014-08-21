module Rift

include("../deps/deps.jl")

import Base: zero

const DK1              = 3
const DKHD             = 4
const DK2              = 6


const ovrHmdCap_Present           = 0x0001
const ovrHmdCap_Available         = 0x0002
const ovrHmdCap_Captured          = 0x0004
const ovrHmdCap_ExtendDesktop     = 0x0008
const ovrHmdCap_NoMirrorToWindow  = 0x2000
const ovrHmdCap_DisplayOff        = 0x0040
const ovrHmdCap_LowPersistence    = 0x0080
const ovrHmdCap_DynamicPrediction = 0x0200
const ovrHmdCap_NoVSync           = 0x1000

const ovrHmdCap_Writable_Mask     = 0x33F0
const ovrHmdCap_Service_Mask      = 0x23F0

immutable ovrFovPort
    UpTan::Float32
    DownTan::Float32
    LeftTan::Float32
    RightTan::Float32
end
zero(::Type{ovrFovPort}) = ovrFovPort(0.0f1,0.0f1,0.0f1,0.0f1)

immutable ovrSizei
    w::Cint
    h::Cint
end
zero(::Type{ovrSizei}) = ovrSizei(0,0)

immutable ovrVector2i
    x::Cint
    y::Cint
end
zero(::Type{ovrVector2i}) = ovrVector2i(0,0)

immutable ovrRecti
    Pos::ovrVector2i
    Size::ovrSizei
end
zero(::Type{ovrRecti}) = ovrRecti(zero(ovrVector2i),zero(ovrSizei))

immutable ovrVector2f
    x::Float32
    y::Float32
end
zero(::Type{ovrVector2f}) = ovrVector2f(0.0f1,0.0f1)

immutable ovrVector3f
    x::Float32
    y::Float32
    z::Float32
end
zero(::Type{ovrVector3f}) = ovrVector3f(0.0f1,0.0f1,0.0f1)

immutable ovrQuatf
    x::Float32
    y::Float32
    z::Float32
    w::Float32
end
zero(::Type{ovrQuatf}) = ovrQuatf(0.0f1,0.0f1,0.0f1,0.0f1)

immutable ovrPosef
    Orientation::ovrQuatf
    Position::ovrVector3f
end
zero(::Type{ovrPosef}) = ovrPosef(zero(ovrQuatf),zero(ovrVector3f))

immutable ovrHmdDesc
    handle::Ptr{Void}
    Type::Cint
    ProductName::Ptr{Uint8}
    Manufacturer::Ptr{Uint8}

    VendorID::Uint16
    ProductId::Uint16
    SerialNumber1::Uint128
    SerialNumber2::Uint64

    FirmwareMajor::Uint16
    FirmwareMinor::Uint16

    CameraFrustumHFovInRadians::Float32
    CameraFrustumVFovInRadians::Float32
    CameraFrustumNearZInMeters::Float32
    CameraFrustumFarZInMeters::Float32

    HmdCaps::Cuint
    TrackingCaps::Cuint
    DistortionCaps::Cuint

    DefaultEyeFovLeft::ovrFovPort
    DefaultEyeFovRight::ovrFovPort

    MaxEyeFov::ovrFovPort

    EyeRenderOrderLeft::Cint
    EyeRenderOrderRight::Cint

    Resolution::ovrSizei
    WindowsPos::ovrVector2i

    DisplayDeviceName::Ptr{Uint8}
    DisplayId::Cint
end

immutable ovrTimingInfo
    DeltaSeconds::Float32
    ThisFrameSeconds::Float64
    TimewarpPointSeconds::Float64
    NextFrameSeconds::Float64
    ScanoutMidpointSeconds::Float64
    EyeScanoutSecondsLeft::Float64
    EyeScanoutSecondsRight::Float64
end


const ovrHmd = Ptr{ovrHmdDesc}


const ovrBool = Uint8

initialize() = ccall((:ovr_Initialize,LibOVR),ovrBool,())
shutdown() = ccall((:ovr_Shutdown,LibOVR),Void,())

immutable HMDList; end

const HMDs = HMDList();

import Base: length, getindex, zero, length, getindex

length(::HMDList) = ccall((:ovrHmd_Detect,LibOVR),Cint,())
getindex(::HMDList,x) = ccall((:ovrHmd_Create,LibOVR),ovrHmd,(Cint,),x+1)

debug_hmd(kind) = ccall((:ovrHmd_CreateDebug,LibOVR),ovrHmd,(Cint,),kind)

function __init__()
    initialize()
end

const ovrRenderAPI_None             = 0
const ovrRenderAPI_OpenGL           = 1
const ovrRenderAPI_Android_GLES     = 2
const ovrRenderAPI_D3D9             = 3
const ovrRenderAPI_D3D10            = 4
const ovrRenderAPI_D3D11            = 5

immutable ovrRenderAPIConfigHeader
    API::Cint
    RTSize::ovrSizei
    Multisample::Cint
end
zero(::Type{ovrRenderAPIConfigHeader}) = ovrRenderAPIConfigHeader(0,zero(ovrSizei),0)

immutable ovrRenderAPIConfig
    Header::ovrRenderAPIConfigHeader
    PlatformData1::Uint
    PlatformData2::Uint
    PlatformData3::Uint
    PlatformData4::Uint
    PlatformData5::Uint
    PlatformData6::Uint
    PlatformData7::Uint
    PlatformData8::Uint
end
zero(::Type{ovrRenderAPIConfig}) =
    ovrRenderAPIConfig(zero(ovrRenderAPIConfigHeader),0,0,0,0,0,0,0,0)

immutable ovrTextureHeader
    API::Cint
    TextureSize::ovrSizei
    RenderViewport::ovrRecti
end

immutable ovrTexture
    Header::ovrTextureHeader
    PlatformData1::Uint
    PlatformData2::Uint
    PlatformData3::Uint
    PlatformData4::Uint
    PlatformData5::Uint
    PlatformData6::Uint
    PlatformData7::Uint
    PlatformData8::Uint
end


const ovrDistortionCap_Chromatic      = 0x01 # Supports chromatic aberration correction.
const ovrDistortionCap_TimeWarp       = 0x02 # Supports timewarp.
const ovrDistortionCap_Vignette       = 0x08 # Supports vignetting around the edges of the view.
const ovrDistortionCap_NoRestore      = 0x10 #  Do not save and restore the graphics state when rendering distortion.
const ovrDistortionCap_FlipInput      = 0x20 #  Flip the vertical texture coordinate of input images.
const ovrDistortionCap_SRGB           = 0x40 #  Assume input images are in sRGB gamma-corrected color space.
const ovrDistortionCap_Overdrive      = 0x80 #  Overdrive brightness transitions to reduce artifacts on DK2+ displays


immutable ovrEyeRenderDesc
    Eye::Cint
    Fov::ovrFovPort
    DistortedViewport::ovrRecti
    PixelsPerTanAngleAtCenter::ovrVector2f
    ViewAdjust::ovrVector3f
end
zero(::Type{ovrEyeRenderDesc}) = ovrEyeRenderDesc(0,zero(ovrFovPort),zero(ovrRecti),zero(ovrVector2f),zero(ovrVector3f))


function ConfigureRendering(hmdhandle::ovrHmd)
    a = zeros(ovrRenderAPIConfig,1)
    a[1] = ovrRenderAPIConfig(ovrRenderAPIConfigHeader(ovrRenderAPI_OpenGL,ovrSizei(1920,1080),1),0,0,0,0,0,0,0,0)

    distortionCaps = ovrDistortionCap_Chromatic | ovrDistortionCap_Vignette;

    Hmd = unsafe_load(hmdhandle)

    eyeFov = Array(ovrFovPort,2)
    eyeFov[1] = Hmd.DefaultEyeFovLeft
    eyeFov[2] = Hmd.DefaultEyeFovRight

    eyeRender = zeros(ovrEyeRenderDesc,2)

    ccall((:ovrHmd_ConfigureRendering,LibOVR),ovrBool,
        (Ptr{Void},Ptr{Void},Cuint,Ptr{Void},Ptr{Void}),
        hmdhandle,a,distortionCaps,eyeFov,eyeRender)
end

enabled_caps(hmd) = ccall((:ovrHmd_GetEnabledCaps, LibOVR), Cuint, (Ptr{Void},), hmd)

function begin_frame(hmd)
    a = Array(ovrTimingInfo,1)
    # This uses sret. The array above won't be needed once the appropriate
    # Julia patch merges
    ccall((:ovrHmd_BeginFrame,LibOVR),Void,(Ptr{Void},Ptr{Void},Cuint),a,hmd,0)
end

function end_frame(hmd,TextureL,viewPortL,TextureR,viewPortR)
    renderPose = Array(ovrPosef,2)
    eyeTexture = Array(ovrTexture, 2)
    eyeTexture[1] = ovrTexture(ovrTextureHeader(
        ovrRenderAPI_OpenGL,
        ovrSizei(TextureL.dims[1],TextureL.dims[2]),
        viewPortL),
        TextureL.id,0,0,0,0,0,0,0)
    eyeTexture[2] = ovrTexture(ovrTextureHeader(
        ovrRenderAPI_OpenGL,
        ovrSizei(TextureR.dims[1],TextureR.dims[2]),
        viewPortR),
        TextureR.id,0,0,0,0,0,0,0)
    ccall((:ovrHmd_EndFrame,LibOVR),Void,(Ptr{Void},Ptr{Void},Ptr{Void}),
        hmd,renderPose,eyeTexture)
end

end # module
