window.onload = ->

    Cfg =
        LIGHT_SPEED: 0.0025
        TRANSITION_TARGET_SPEED: 0.05
        RADIUS: 245
        CAMERA_Y: 500
        CITY_COLOR: '#FFAA22'
        AMBIENT_COLOR: '#1A2024'
        SHADOW_BIAS: 0.0001
        SHADOW_DARKNESS: 0.5
        CUSTOM_COLORS: false

    Themes = [
        # Ghost
        {
            cityColor: '#FFFFFF'
            ambientColor: '#484848'
            cityRadius: 150
            buildingsNumber: 50
            cubesNumber: 0
            cubeSize: 0
        }

        # Green/Red
        {
            cityColor: '#FF2020'
            ambientColor: '#336464'
            cityRadius: 150
            buildingsNumber: 50
            cubesNumber: 10
            cubeSize: 100
        }

        # Winter
        {
            cityColor: '#21F2FF'
            ambientColor: '#417EA7'
            cityRadius: 150
            buildingsNumber: 100
            cubesNumber: 10
            cubeSize: 50
        }

        # Night winter
        {
            cityColor: '#0069FF'
            ambientColor: '#212528'
            cityRadius: 50
            buildingsNumber: 400
            cubesNumber: 10
            cubeSize: 150
        }

        # Joker
        {
            cityColor: '#00FF77'
            ambientColor: '#231137'
            cityRadius: 200
            buildingsNumber: 300
            cubesNumber: 20
            cubeSize: 100
        }

        # Violet/Pink
        {
            cityColor: '#C365AC'
            ambientColor: '#3B2389'
            cityRadius: 250
            buildingsNumber: 400
            cubesNumber: 50
            cubeSize: 200
        }

        # Green
        {
            cityColor: '#00FF96'
            ambientColor: '#162A16'
            cityRadius: 250
            buildingsNumber: 500
            cubesNumber: 50
            cubeSize: 250
        }

        # Sands
        {
            cityColor: '#FFA400'
            ambientColor: '#4A2C0A'
            cityRadius: 150
            buildingsNumber: 50
            cubesNumber: 20
            cubeSize: 150
        }

        # Gotham
        {
            cityColor: '#FFAA22'
            ambientColor: '#20242A'
            cityRadius: 250
            buildingsNumber: 600
            cubesNumber: 50
            cubeSize: 300
        }

    ]

    PI     = Math.PI
    PI2    = Math.PI*2


    # App elements
    city    = null
    ambient = null    
    plane   = null
    circle  = null
    light   = null

    # Smooth movement
    ax       = 0
    vx       = 0
    ay       = 0
    vy       = 0
    friction = 0.93
    limit    = 0.05
    limitAcc = 0.005


    # Variables
    targetPos   = new THREE.Vector3

    cameraAngle =  0
    lightAngle  = 100

    isTargeted = false
    isAnimated = false

    themePos    = -1
    theme = Themes[themePos]




    # Initilize scene & renderer
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
        if not (isTargeted and (isAnimated or Utils.RadiusDetection(camera, circle)))
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
        if isTargeted or (not isTargeted and Utils.RadiusDetection(camera, circle))
            targetPos.x += (circle.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.y += (circle.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.z += (circle.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED
        else
            targetPos.x += (scene.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.y += (scene.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.z += (scene.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED

        # Animate targeted
        if isTargeted and not Utils.RadiusDetection(camera, circle)
            ax += 0.05
        else if isTargeted and Utils.RadiusDetection(camera, circle) and not isAnimated
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
                                                DarkGrey.Scene.restart()



    Utils = 
        map_range: (value, low1, high1, low2, high2)->
                return low2 + (high2 - low2) * (value - low1) / (high1 - low1)

        RadiusDetection: (obj1, obj2)->
            obj1Angle = Math.atan2(obj1.position.z, obj1.position.x)
            obj2Angle = Math.atan2(obj2.position.z, obj2.position.x)
            return (obj1Angle > obj2Angle - PI / 8 and obj1Angle < obj2Angle + PI / 8)


    # BUILDING Object
    Building = (theme)->
        @geometry = @Geometry()
        return @Mesh({ radius: theme.cityRadius })

    Building.prototype = 
        Geometry: ->
            # Building geometry
            geometry = new THREE.CubeGeometry 1, 1, 1
            geometry.applyMatrix new THREE.Matrix4().makeTranslation 0, 0.5, 0
            
            return geometry

        Mesh: (params)->
            targetAngle = Math.random() * PI2

            # Building mesh
            mesh = new THREE.Mesh(@geometry)
            mesh.position.x = Math.cos(targetAngle) * (Math.random()+0.1) * params.radius
            mesh.position.z = Math.sin(targetAngle) * (Math.random()+0.1) * params.radius
            mesh.position.y = 0

            mesh.scale.x = Math.random()*Math.random()*Math.random()*Math.random() * 50 + 10
            mesh.scale.z = mesh.scale.x
            mesh.scale.y = (Math.random() * Math.random() * Math.random() * mesh.scale.x) * 10 + 10

            return mesh             


    # CUBE Object
    Cube = ->
        @geometry = @Geometry()
        return @Mesh({ cubeSize: theme.cubeSize })

    Cube.prototype =
        Geometry: ->
            geometry = new THREE.CubeGeometry 1, 1, 1
            geometry.applyMatrix new THREE.Matrix4().makeTranslation 0, -0.5, 0
            return geometry

        Mesh: (params)->
            targetAngle = Math.random() * PI2

            mesh = new THREE.Mesh(@geometry)
            mesh.position.x = Math.cos(targetAngle) * 600
            mesh.position.z = Math.sin(targetAngle) * 600
            mesh.position.y = 400 * Math.random() + 100

            scale = Math.random() * Math.random() * params.cubeSize

            mesh.scale.set scale, scale, scale

            mesh.rotation.x = Math.random() * PI2
            mesh.rotation.y = Math.random() * PI2
            mesh.rotation.z = Math.random() * PI2

            return mesh



    # CITY Object
    City = (theme)->
        @theme = theme
        @geometry = new THREE.Geometry
        @material = @Material(theme.cityColor)
        @generateCity()
        return @Mesh()

    City.prototype = 
        Material: (color)->
            matColor = new THREE.Color(color)
            return new THREE.MeshPhongMaterial
                color: matColor.getHex()

        Mesh: ->
            mesh = new THREE.Mesh(@geometry, @material)
            mesh.scale.set 1, 1, 1
            mesh.castShadow    = true
            mesh.receiveShadow = true

            return mesh

        generateCity: ->
            @ground()
            @buildings()
            @cubes()

        buildings: ->
            i = 0
            while i < @theme.buildingsNumber
                building = new Building(@theme)

                if building.position.distanceTo(scene.position) > @theme.cityRadius - 50 and not circle
                    plane = new THREE.Mesh(new THREE.PlaneGeometry(50, 50), new THREE.MeshBasicMaterial({ map:THREE.ImageUtils.loadTexture('images/portal.png'), wireframe: false, transparent: true }))
                    plane.position.y = 2
                    plane.rotation.x = -PI / 2

                    circleColor = new THREE.Color(Cfg.CITY_COLOR)
                    circle = new THREE.Mesh new THREE.SphereGeometry(2.5, 100, 100), new THREE.MeshLambertMaterial({ color: circleColor.getHex() })
                    circle.position.x = building.position.x
                    circle.position.z = building.position.z
                    circle.position.y = building.position.y + 100
                    circle.castShadow = true
                    scene.add circle

                THREE.GeometryUtils.merge(@geometry, building)

                i++

        cubes: ->
            i = 0
            while i < @theme.cubesNumber
                cube = new Cube(@theme)
                THREE.GeometryUtils.merge(@geometry, cube)
                i++

        ground: ->
            groundGeometry                    = new THREE.PlaneGeometry 400, 400
            groundGeometry.verticesNeedUpdate = true
            
            groundMaterial         = @material
            groundMaterial.ambiant = @material

            ground               = new THREE.Mesh groundGeometry, groundMaterial
            ground.rotation.x    = -PI / 2
            ground.scale.set 100, 100, 100
            ground.castShadow    = true
            ground.receiveShadow = true

            THREE.GeometryUtils.merge(@geometry, ground)


    Light =
        Ambient: (color)->
            ambientColor = new THREE.Color(color)
            ambient      = new THREE.AmbientLight(ambientColor.getHex())
            return ambient

        Spot: (color)->
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

            return light           


    Skybox = ->
        return @Mesh()

    Skybox.prototype =
        Geometry: ->
            return new THREE.CubeGeometry(10000, 10000, 10000)

        Material: ->
            return new THREE.MeshPhongMaterial({ color: 0xd0e0f0, side: THREE.BackSide })

        Mesh: ->
            mesh = new THREE.Mesh( new THREE.CubeGeometry(10000, 10000, 10000), new THREE.MeshPhongMaterial({ color: 0xd0e0f0, side: THREE.BackSide }) )
            return mesh


    # MUSIC
    music = new Howl(
        urls: ['plane.mp3']
        volume: 0.5
        loop: true
    )#.play()

    breath0 = new Howl(
        urls: ['breath0.wav']
        volume: 0.25
    )

    breath1 = new Howl(
        urls: ['wind.mp3']
        volume: 0.25
    )

    DarkGrey =
        Scene:
            init: ->
                skybox = new Skybox()
                scene.add(skybox)

                light = new Light.Spot()
                scene.add(light)

            clean: ->
                scene.remove plane
                scene.remove circle
                scene.remove city
                scene.remove ambient            

                circle = null
                camera.lookAt scene.position

            start: ->
                # Initialize scene
                camera.position.set 5000, 2000, 5000
                isTargeted = false
                isAnimated = false

                themePos++
                if themePos >= Themes.length
                    themePos = 0

                theme             = Themes[themePos]
                Cfg.CITY_COLOR    = if Cfg.CUSTOM_COLORS then Cfg.CITY_COLOR else theme.cityColor
                Cfg.AMBIENT_COLOR = if Cfg.CUSTOM_COLORS then Cfg.AMBIENT_COLOR else theme.ambientColor

                city = new City(theme)
                scene.add(city)

                ambient = new Light.Ambient(Cfg.AMBIENT_COLOR)
                scene.add(ambient)
                
                # Launch animations & sounds
                breath0.fadeOut(0, 2000, -> breath0.stop())
                breath1.fadeOut(0, 2000, -> breath1.stop())

                TweenMax.to camera.position, 1.5,
                    y:150
                TweenMax.to Cfg, 1.5,
                    RADIUS: 245

            restart: ->
                @clean()
                @start()

            render: ->
                scene.add light
                render()

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

        initGui: ->
            gui = new dat.GUI()
            gui.add(Cfg, 'TRANSITION_TARGET_SPEED', 0, 1).name('target speed').listen()
            gui.add(Cfg, 'LIGHT_SPEED', 0, 0.01).name('light speed').listen()
            gui.add(Cfg, 'RADIUS').name('Camera radius').listen()
            gui.addColor(Cfg, 'CITY_COLOR').name('City color').listen()
            gui.addColor(Cfg, 'AMBIENT_COLOR').name('Ambiant color').listen()
            gui.add(camera.position, 'y').name('Camera Y').listen()
            gui.add(Cfg, 'SHADOW_BIAS').name('Shadow bias')
            gui.add(Cfg, 'SHADOW_DARKNESS').name('Shadow darkness')
            gui.add(Cfg, 'CUSTOM_COLORS').name('custom colors')
            gui.close()

        init: ->
            @events()
            @initGui()
            @Scene.init()

    DarkGrey.init()
    DarkGrey.Scene.start()
    DarkGrey.Scene.render()
