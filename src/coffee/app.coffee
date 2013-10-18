window.onload = ->

    Cfg =
        LIGHT_SPEED: 0.0025
        TRANSITION_TARGET_SPEED: 0.05
        RADIUS: 245
        CAMERA_Y: 500
        CITY_COLOR: '#FFAA22'
        AMBIANT_COLOR: '#1A2024'
        SHADOW_BIAS: 0.0001
        SHADOW_DARKNESS: 0.5
        CUSTOM_COLORS: false

    Themes = [
        # Ghost
        {
            cityColor: '#FFFFFF'
            ambiantColor: '#484848'
            cityRadius: 150
            buildingsNumber: 50
            cubesNumber: 0
            cubeSize: 0
        }

        # Winter
        {
            cityColor: '#21F2FF'
            ambiantColor: '#417EA7'
            cityRadius: 150
            buildingsNumber: 100
            cubesNumber: 10
            cubeSize: 50
        }

        # Joker
        {
            cityColor: '#00FFB3'
            ambiantColor: '#231137'
            cityRadius: 200
            buildingsNumber: 300
            cubesNumber: 20
            cubeSize: 100
        }

        # Violet/Pink
        {
            cityColor: '#C365AC'
            ambiantColor: '#3B2389'
            cityRadius: 250
            buildingsNumber: 400
            cubesNumber: 50
            cubeSize: 200
        }

        # Green
        {
            cityColor: '#00FF96'
            ambiantColor: '#162A16'
            cityRadius: 250
            buildingsNumber: 500
            cubesNumber: 50
            cubeSize: 250
        }

        # Gotham
        {
            cityColor: '#FFAA22'
            ambiantColor: '#20242A'
            cityRadius: 250
            buildingsNumber: 600
            cubesNumber: 50
            cubeSize: 300
        }

        # Green/Red
        {
            cityColor: '#FF2020'
            ambiantColor: '#46705A'
            cityRadius: 250
            buildingsNumber: 600
            cubesNumber: 50
            cubeSize: 400
        }

        # Green/Red
        {
            cityColor: '#FF2020'
            ambiantColor: '#336464'
            cityRadius: 150
            buildingsNumber: 50
            cubesNumber: 10
            cubeSize: 150
        }

    ]

    PI     = Math.PI
    PI2    = Math.PI*2

    # Smooth movement
    ax       = 0
    vx       = 0
    ay       = 0
    vy       = 0
    friction = 0.93
    limit    = 0.05
    limitAcc = 0.005

    city    = null
    ambiant = null


    targetPos   = new THREE.Vector3
    plane = null

    cameraAngle =  0
    lightAngle  = 100

    circle = null
    distanceCirle = 0

    projector = new THREE.Projector

    isTargeted = false
    isAnimated = false

    cirTanAngle = 0
    themePos    = -1

    theme = Themes[themePos]





    scene     = new THREE.Scene
    scene.fog = new THREE.FogExp2( 0xd0e0f0, 0.0020 )

    camera            = new THREE.PerspectiveCamera 75, window.innerWidth / window.innerHeight, 0.1, 10000
    camera.position.y = 150

    renderer =  new THREE.WebGLRenderer antialias: false
    renderer.shadowMapEnabled = true
    renderer.shadowMapSoft    = true
    renderer.shadowMapType    = THREE.PCFShadowMap
    renderer.setSize window.innerWidth, window.innerHeight
    document.body.appendChild renderer.domElement




    clearMask = new THREE.ClearMaskPass()
    renderModel = new THREE.RenderPass( scene, camera )

    renderMaskInverse = new THREE.MaskPass( scene, camera );
    renderMaskInverse.inverse = true

    effectHBlur = new THREE.ShaderPass( THREE.HorizontalBlurShader )
    effectVBlur = new THREE.ShaderPass( THREE.VerticalBlurShader )
    effectHBlur.uniforms[ 'h' ].value = 2 / ( window.innerWidth / 2 )
    effectVBlur.uniforms[ 'v' ].value = 2 / ( window.innerHeight / 2 )

    effectFilm = new THREE.FilmPass( 0.05, 0, 0, false )
    effectFilmBW = new THREE.FilmPass( 0.35, 0.5, 2048, true )

    shaderVignette = THREE.VignetteShader
    effectVignette = new THREE.ShaderPass( shaderVignette )
    effectVignette.uniforms[ "offset" ].value = 0.5
    effectVignette.uniforms[ "darkness" ].value = 1.6

    effect = new THREE.ShaderPass( THREE.BleachBypassShader );
    # effect.uniforms[ 'tDiffuse2' ].value = effectSave.renderTarget;
    # effect.uniforms[ 'mixRatio' ].value = 0.65

    # effectSave = new THREE.SavePass( new THREE.WebGLRenderTarget( window.innerWidth, window.innerWidth, { minFilter: THREE.LinearFilter, magFilter: THREE.LinearFilter, format: THREE.RGBFormat, stencilBuffer: false } ) )
    effectFilm.renderToScreen = true

    # effect.enabled = true
    # effectSave.enabled = true

    # effect.renderToScreen = true


    rtParams =
        minFilter: THREE.LinearFilter
        magFilter: THREE.LinearFilter
        format: THREE.RGBFormat
        stencilBuffer: true


    composer = new THREE.EffectComposer( renderer, new THREE.WebGLRenderTarget( window.innerWidth, window.innerWidth, rtParams ) )

    composer.addPass( renderModel )
    composer.addPass( effectFilm )
    # composer.addPass( effect )
    # composer.addPass( effectSave )


    light2  = new THREE.SpotLight 0xd0e0f0, 25, 0, PI / 16, 100
    light2.position.y = 50
    scene.add light2

    light  = new THREE.SpotLight 0xFFFFFF, 4, 0, PI / 16, 500
    light.position.set 0, Cfg.CAMERA_Y, 0
    light.target.position.set 0, 0, 0

    light.castShadow          = true

    light.shadowCameraNear    = 700
    light.shadowCameraFar     = camera.far
    light.shadowCameraFov     = 50

    light.shadowBias          = Cfg.SHADOW_BIAS
    light.shadowDarkness      = Cfg.SHADOW_DARKNESS

    light.shadowCameraRight    =  5
    light.shadowCameraLeft     = -5
    light.shadowCameraTop      =  5
    light.shadowCameraBottom   = -5

    light.shadowMapWidth      = 2048
    light.shadowMapHeight     = 2048

    skyboxMesh = new THREE.Mesh( new THREE.CubeGeometry(10000, 10000, 10000), new THREE.MeshPhongMaterial({ color: 0xd0e0f0, side: THREE.BackSide }) )
    scene.add skyboxMesh


    # MUSIC
    music = new Howl(
        urls: ['plane.mp3']
        volume: 0.5
        loop: true
    ).play()

    breath0 = new Howl(
        urls: ['breath0.wav']
        volume: 0.25
    )

    breath1 = new Howl(
        urls: ['wind.mp3']
        volume: 0.25
    )


    map_range = (value, low1, high1, low2, high2)->
        return low2 + (high2 - low2) * (value - low1) / (high1 - low1)

    inRadius = (obj1, obj2)->
        obj1Angle = Math.atan2(obj1.position.z, obj1.position.x)
        obj2Angle = Math.atan2(obj2.position.z, obj2.position.x)
        return (obj1Angle > obj2Angle - PI / 8 and obj1Angle < obj2Angle + PI / 8)

    #Render the @scene
    render = ->
        requestAnimationFrame render

        rotateLight()
        moveCamera()

        composer.render(0.01)

    rotateLight = ->
        # Rotate light
        lightAngle += Cfg.LIGHT_SPEED
        light.position.x = 700 * Math.cos(lightAngle)
        light.position.z = 700 * Math.sin(lightAngle)
        light.position.y = 500

    moveCamera = ->
        if not (isTargeted and (isAnimated or inRadius(camera, circle)))
            # Rotate camera
            ax = Math.max(Math.min(limitAcc, ax), -limitAcc)
            ax *= friction
            vx *= friction
            vx += ax
            vx = Math.max(Math.min(limit, vx), -limit)
            cameraAngle += vx

            camera.position.x = 1.5 * Cfg.RADIUS * Math.cos cameraAngle
            camera.position.z = 1.5 * Cfg.RADIUS * Math.sin cameraAngle

            ay = Math.max(Math.min(5, ay), -5)
            ay *= friction
            vy *= friction
            vy += ay
            vy = Math.max(Math.min(5, vy), -5)

            if camera.position.y < 5 or camera.position.y > 300
                vy = vy*-1

            camera.position.y += vy

        # Target city or ellipse
        if isTargeted or (not isTargeted and inRadius(camera, circle))
            targetPos.x += (circle.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.y += (circle.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.z += (circle.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED
        else
            targetPos.x += (scene.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.y += (scene.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.z += (scene.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED

        # Animate targeted
        if isTargeted and not inRadius(camera, circle)
            ax += 0.05
        else if isTargeted and inRadius(camera, circle) and not isAnimated
            ax = 0
            isAnimated = true
            animateCam()

        camera.lookAt targetPos

    animateCam = ->
        TweenMax.to circle.position, 1,
                x:plane.position.x
                y:plane.position.y + 300
                z:plane.position.z
                ease: Expo.easeInOut
                delay:0.25
                onStart: ->
                    breath1.stop().fadeIn(0.5, 1000)
                    breath1.play().fadeOut(0, 1000)
                onComplete: ->
                    TweenMax.to camera.position, 1,
                        x:circle.position.x+25
                        y:circle.position.y+25
                        z:circle.position.z-25
                        ease: Expo.easeInOut
                        delay: 0.5
                        onStart: ->
                            breath0.stop().fadeIn(0.5, 1000)
                            breath0.play().fadeOut(0, 1000)
                        onComplete: ->
                            scene.add plane
                            TweenMax.to circle.position, 1,
                                    y: -100
                                    ease: Expo.easeInOut
                                    delay:0.25
                                    onStart: ->
                                        breath1.stop().fadeIn(0.5, 1000)
                                        breath1.play().fadeOut(0, 1000)
                                    onComplete: ->
                                        TweenMax.to camera.position, 0.5,
                                            delay:0.25
                                            x:circle.position.x
                                            y:plane.position.y + 1
                                            z:circle.position.z
                                            ease: Expo.easeInOut
                                            onStart: ->
                                                breath0.stop().fadeIn(0.5, 1000)
                                                breath0.play().fadeOut(0, 1000)
                                            onComplete: ->
                                                DarkGrey.restartScene()

    # Building geometry
    buildGeometry = new THREE.CubeGeometry 1, 1, 1
    buildGeometry.applyMatrix new THREE.Matrix4().makeTranslation 0, 0.5, 0

    cubeGeometry = new THREE.CubeGeometry 1, 1, 1
    cubeGeometry.applyMatrix new THREE.Matrix4().makeTranslation 0, -0.5, 0

    DarkGrey =
        # Create buildings
        buildingMesh: (i)->
            targetAngle = Math.random() * PI2

            # Building mesh
            mesh = new THREE.Mesh buildGeometry
            mesh.position.x = Math.cos(targetAngle) * (Math.random()+0.075) * theme.cityRadius
            mesh.position.z = Math.sin(targetAngle) * (Math.random()+0.075) * theme.cityRadius
            mesh.position.y = 0

            mesh.scale.x = Math.random()*Math.random()*Math.random()*Math.random() * 50 + 10
            mesh.scale.z = mesh.scale.x
            mesh.scale.y = (Math.random() * Math.random() * Math.random() * mesh.scale.x) * 8 + 8

            if mesh.position.distanceTo(scene.position) > theme.cityRadius - 50 and not circle
                plane = new THREE.Mesh(new THREE.PlaneGeometry(50, 50), new THREE.MeshBasicMaterial({ map:THREE.ImageUtils.loadTexture('images/portal.png'), wireframe: false, transparent: true }))
                plane.position.y = 2
                plane.rotation.x = -PI / 2

                circleColor = new THREE.Color(Cfg.CITY_COLOR)
                circle = new THREE.Mesh new THREE.SphereGeometry(2.5, 100, 100), new THREE.MeshLambertMaterial({ color: circleColor.getHex() })
                circle.position.x = mesh.position.x
                circle.position.z = mesh.position.z
                circle.position.y = mesh.position.y + 100
                circle.castShadow = true
                scene.add circle

                distanceCirle = circle.position.distanceTo scene.position

            return mesh

        # Create buildings
        buildSquare: (i)->
            targetAngle = Math.random() * PI2

            # Building mesh

            mesh = new THREE.Mesh(cubeGeometry)
            mesh.position.x = Math.cos(targetAngle) * 600
            mesh.position.z = Math.sin(targetAngle) * 600
            mesh.position.y = 400 * Math.random() + 100

            scale = Math.random() * Math.random() * theme.cubeSize

            mesh.scale.set scale, scale, scale

            mesh.rotation.x = Math.random() * PI2
            mesh.rotation.y = Math.random() * PI2
            mesh.rotation.z = Math.random() * PI2

            return mesh


        # Create city
        cityMesh: ->
            # Ground
            planeColor                       = new THREE.Color(Cfg.CITY_COLOR)
            planeGeometry                    = new THREE.PlaneGeometry 400, 400
            planeGeometry.verticesNeedUpdate = true
            planeMaterial = new THREE.MeshPhongMaterial
                color: planeColor.getHex()
            planeMaterial.ambiant = planeMaterial.color

            ground               = new THREE.Mesh planeGeometry, planeMaterial
            ground.rotation.x    = -PI / 2
            ground.scale.set 100, 100, 100
            ground.castShadow    = true
            ground.receiveShadow = true

            # City
            cityGeometry = new THREE.Geometry
            i = 0
            while i < theme.buildingsNumber
            # for i in [0...600]
                THREE.GeometryUtils.merge cityGeometry, @buildingMesh(i)
                i++

            decoGeometry = new THREE.Geometry
            j = 0
            while j < theme.cubesNumber
                THREE.GeometryUtils.merge decoGeometry, @buildSquare()
                j++

            THREE.GeometryUtils.merge cityGeometry, ground
            THREE.GeometryUtils.merge cityGeometry, decoGeometry

            cityMesh = new THREE.Mesh cityGeometry, planeMaterial
            cityMesh.scale.set 1, 1, 1
            cityMesh.castShadow    = true
            cityMesh.receiveShadow = true

            return cityMesh

        # Ligths
        lights: ->
            ambiantColor = new THREE.Color(Cfg.AMBIANT_COLOR)
            return ambient = new THREE.AmbientLight(ambiantColor.getHex())

        events: ->
            document.addEventListener 'keydown', (e)->
                if not isTargeted
                    if e.keyCode == 37
                        ax += 0.001
                    if e.keyCode == 39
                        ax -= 0.001
                    if e.keyCode == 38
                        ay += 0.05
                    if e.keyCode == 40
                        ay -= 0.05

                    if e.keyCode == 32
                        isTargeted = true

        restartScene: ->
            breath0.fadeOut(0, 2000, -> breath0.stop())
            breath1.fadeOut(0, 2000, -> breath1.stop())

            camera.position.set 5000, 2000, 5000
            isTargeted = false
            isAnimated = false

            themePos++
            if themePos >= Themes.length
                themePos = 0

            theme             = Themes[themePos]
            Cfg.CITY_COLOR    = if Cfg.CUSTOM_COLORS then Cfg.CITY_COLOR else theme.cityColor
            Cfg.AMBIANT_COLOR = if Cfg.CUSTOM_COLORS then Cfg.AMBIANT_COLOR else theme.ambiantColor

            scene.remove plane
            scene.remove circle
            scene.remove city
            scene.remove ambiant

            circle = null
            camera.lookAt scene.position

            scene.add    city = DarkGrey.cityMesh()
            scene.add    ambiant = DarkGrey.lights()

            TweenMax.to camera.position, 1.5,
                y:150
            TweenMax.to Cfg, 1.5,
                RADIUS: 245

        initGui: ->
            gui = new dat.GUI()
            gui.add(Cfg, 'TRANSITION_TARGET_SPEED', 0, 1).name('target speed').listen()
            gui.add(Cfg, 'LIGHT_SPEED', 0, 0.01).name('light speed').listen()
            gui.add(Cfg, 'RADIUS').name('Camera radius').listen()
            gui.addColor(Cfg, 'CITY_COLOR').name('City color').listen()
            gui.addColor(Cfg, 'AMBIANT_COLOR').name('Ambiant color').listen()
            gui.add(camera.position, 'y').name('Camera Y').listen()
            gui.add(Cfg, 'SHADOW_BIAS').name('Shadow bias')
            gui.add(Cfg, 'SHADOW_DARKNESS').name('Shadow darkness')
            gui.add(Cfg, 'CUSTOM_COLORS').name('custom colors')
            gui.close()

        init: ->
            @events()
            @initGui()

        renderScene: ->
            scene.add light

            render()

    DarkGrey.init()
    DarkGrey.restartScene()
    DarkGrey.renderScene()
