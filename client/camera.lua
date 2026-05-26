Camera = Camera or {}
Camera.Handle = nil

function Camera.Destroy()
    if Camera.Handle then
        RenderScriptCams(false, true, 250, true, true)
        DestroyCam(Camera.Handle, false)
        Camera.Handle = nil
    end
end

function Camera.Create(config)
    Camera.Destroy()

    if not config or not config.coords then
        return nil
    end

    Camera.Handle = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamCoord(Camera.Handle, config.coords.x, config.coords.y, config.coords.z)

    if config.rotation then
        SetCamRot(Camera.Handle, config.rotation.x or 0.0, config.rotation.y or 0.0, config.rotation.z or 0.0, 2)
    end

    SetCamFov(Camera.Handle, config.fov or 50.0)
    RenderScriptCams(true, true, 250, true, true)

    return Camera.Handle
end

function Camera.FocusGarage(garage)
    if not garage or not garage.camera then
        return nil
    end

    return Camera.Create(garage.camera)
end
