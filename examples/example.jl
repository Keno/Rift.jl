using GLWindow, GLAbstraction, GLFW, ModernGL, React, GLPlot, ImmutableArrays
half_frame  = [960, 1080]
frame       = half_frame .* [2,1]

# When oculus works, you can just make dummy window with width,heigh = (1,1)
window = createwindow("Dummy", frame..., debugging = false) # debugging just works on linux and windows


# Camera setup
inputsL = copy(window.inputs)
inputsR = copy(window.inputs)
inputsL[:window_size] = Input(Vector4(0, 0, half_frame...))
inputsR[:window_size] = Input(Vector4(half_frame[1], 0, half_frame...))
const camL = PerspectiveCamera(inputsL, Vec3(3.0f0, 0.0f0, 0f0), Vec3(0f0, 0f0, 0f0))
const camR = PerspectiveCamera(inputsR, Vec3(3.0f0, 0.2f0, 0f0), Vec3(0f0, 0f0, 0f0))


# Data setup
function zdata(x1, y1, factor)
    x = (x1 - 0.5) * 15
    y = (y1 - 0.5) * 15
    R = sqrt(x^2 + y^2)
    Z = sin(R)/R
    Vec1(Z)
end
N         = 128
texdata   = [zdata(i/N, j/N, 5) for i=1:N, j=1:N]
color     = lift(x-> Vec4(sin(x), 0,1,1), Vec4, Timing.every(0.1)) # Example on how to use react to change the color over time
objL = toopengl(texdata, primitive=SURFACE(), color=color, camera=camL) 
objR = toopengl(texdata, primitive=SURFACE(), color=color, camera=camR) 


#Framebuffer + Texture setup
fb = glGenFramebuffers()
glBindFramebuffer(GL_FRAMEBUFFER, fb)

parameters = [
        (GL_TEXTURE_WRAP_S,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_WRAP_T,  GL_CLAMP_TO_EDGE),
        (GL_TEXTURE_MIN_FILTER, GL_NEAREST),
        (GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    ]

# Create the texture which can be used by the oculus SDK:
oculustexture   = Texture(GLfloat, 3, frame, format=GL_RGB, internalformat=GL_RGB8)
glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, oculustexture.id, 0)


rboDepthStencil = GLuint[0]
glGenRenderbuffers(1, rboDepthStencil);
glBindRenderbuffer(GL_RENDERBUFFER, rboDepthStencil[1])
glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, frame...)
glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, rboDepthStencil[1])


# This is just for testing. I viusalize the oculus texture with GLPlot and a camera, which doesn't move
#ocam = OrthographicCamera(Input(Vector4(0,0,frame...)), Input(1f0), Input(Vec2(0)), Input(Vector2(0.0)))
#testimage = toopengl(oculustexture, camera=ocam)


using Rift
Rift.initialize()
hmd = Rift.debug_hmd(Rift.DK2)

@show hmd
@assert hmd != C_NULL

Rift.ConfigureRendering(hmd)

# Renderloop
glClearColor(1,1,1,0)
while !GLFW.WindowShouldClose(window.glfwWindow)

    Rift.begin_frame(hmd)

    glBindFramebuffer(GL_FRAMEBUFFER, fb)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)

    glViewport(0, 0, half_frame...)
    render(objL)
    glViewport(half_frame[1], 0, half_frame...)
    render(objR)

    Rift.end_frame(hmd,oculustexture,Rift.ovrRecti(Rift.ovrVector2i(0,0),Rift.ovrSizei(half_frame...)),
        oculustexture,Rift.ovrRecti(Rift.ovrVector2i(half_frame[1],0),Rift.ovrSizei(half_frame...)))

    #### Needed for events and GLFW
    yield() # this is needed for react to work
    #GLFW.SwapBuffers(window.glfwWindow) # <-- probably not needed, when using the oculus
    GLFW.PollEvents()

end
GLFW.Terminate()