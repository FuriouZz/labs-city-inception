window.onload = ->

    Cfg =
        LIGHT_SPEED: 0.0025
        TRANSITION_TARGET_SPEED: 0.05
        RADIUS: 245
        CAMERA_Y: 500
        CITY_COLOR: '#FFAA22'
        AMBIANT_COLOR: '#1A2024'

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

    scene     = new THREE.Scene
    scene.fog = new THREE.FogExp2( 0xd0e0f0, 0.0015 )

    camera            = new THREE.PerspectiveCamera 75, window.innerWidth / window.innerHeight, 0.1, 10000
    camera.position.y = 150

    renderer =  new THREE.WebGLRenderer antialias: true
    renderer.shadowMapEnabled = true
    renderer.shadowMapSoft    = true
    renderer.shadowMapType    = THREE.PCFShadowMap
    renderer.setSize window.innerWidth, window.innerHeight
    document.body.appendChild renderer.domElement

    light  = new THREE.SpotLight 0xFFFFFF, 4, 0, PI / 16, 500
    light.position.set 0, Cfg.CAMERA_Y, 0
    light.target.position.set 0, 0, 0

    light.castShadow          = true

    light.shadowCameraNear    = 700
    light.shadowCameraFar     = camera.far
    light.shadowCameraFov     = 50

    light.shadowBias          = 0.0001
    light.shadowDarkness      = 0.5

    light.shadowMapWidth      = 1024
    light.shadowMapHeight     = 1024

    helper = new THREE.SpotLightHelper light, 50

    targetPos = new THREE.Vector3

    cameraAngle =  0
    lightAngle  = 100

    circle = null
    distanceCirle = 0

    targeted = false

    map_range = (value, low1, high1, low2, high2)->
        return low2 + (high2 - low2) * (value - low1) / (high1 - low1)


    #Render the @scene
    render = ->
        requestAnimationFrame render

        if not targeted
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

        camera.position.y += vy

        # Rotate light
        lightAngle += Cfg.LIGHT_SPEED
        light.position.x = 700 * Math.cos(lightAngle)
        light.position.z = 700 * Math.sin(lightAngle)
        light.position.y = 500

        # Target city or ellipse
        camTanAngle = Math.atan2(camera.position.z, camera.position.x)
        cirTanAngle = Math.atan2(circle.position.z, circle.position.x)
        if (camTanAngle > cirTanAngle - PI / 8) and (camTanAngle < cirTanAngle + PI / 8)
            targetPos.x += (circle.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.y += (circle.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.z += (circle.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED


            if not targeted
                TweenMax.to(camera.position, 3,
                    x:Math.floor(circle.position.x+25)
                    y:Math.floor(circle.position.y+25)
                    z:Math.floor(circle.position.z+25)
                    onComplete: ->
                        console.log 'hello'
                    ease: Expo.easeOut
                )

            targeted = true

        else
            targetPos.x += (scene.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.y += (scene.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED
            targetPos.z += (scene.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED
            targeted = false

        camera.lookAt targetPos

        # test = (camera.position.y - circle.position.y) * 0.02
        # camera.position.y -= test

        # camera.position.y = map_range(camera.position.distanceTo(circle.position), distanceCirle, 500, circle.position.y, 250)


        # dist = camera.position.distanceTo circle.position
        # if dist < 100
        #     DarkGrey.restartScene()

        renderer.render scene, camera

    # Building geometry
    buildGeometry = new THREE.CubeGeometry 1, 1, 1
    buildGeometry.applyMatrix new THREE.Matrix4().makeTranslation 0, 0.5, 0



    DarkGrey =
        # Create buildings
        buildingMesh: (i)->
            targetAngle = Math.random() * PI2

            # Building mesh
            mesh = new THREE.Mesh buildGeometry
            mesh.position.x = Math.cos(targetAngle) * Math.random() * 250
            mesh.position.z = Math.sin(targetAngle) * Math.random() * 250
            mesh.position.y = Math.random()*PI2

            mesh.scale.x = Math.random()*Math.random()*Math.random()*Math.random() * 50 + 10
            mesh.scale.z = mesh.scale.x
            mesh.scale.y = (Math.random() * Math.random() * Math.random() * mesh.scale.x) * 8 + 8

            if mesh.position.distanceTo(scene.position) > 150.0 and not circle
                console.log 'haaalllooo'
                circleColor = new THREE.Color(Cfg.CITY_COLOR)
                circle = new THREE.Mesh new THREE.SphereGeometry(10, 100, 100), new THREE.MeshLambertMaterial({ color: circleColor.getHex() })
                circle.position.x = mesh.position.x
                circle.position.z = mesh.position.z
                circle.position.y = 0 #mesh.position.y + mesh.scale.y + 100
                circle.castShadow = true
                scene.add circle

                distanceCirle = circle.position.distanceTo scene.position

            return mesh

        # Create city
        cityMesh: ->
            # Ground
            planeColor = new THREE.Color(Cfg.CITY_COLOR)
            planeGeometry = new THREE.PlaneGeometry 400, 400
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
            for i in [0...500]
                THREE.GeometryUtils.merge cityGeometry, @buildingMesh(i)

            THREE.GeometryUtils.merge cityGeometry, ground

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
                if e.keyCode == 37
                    ax += 0.001
                if e.keyCode == 39
                    ax -= 0.001
                if e.keyCode == 38
                    ay += 0.05

                    # if targeted
                        # camera.position.y = map_range(camera.position.distanceTo(circle.position), distanceCirle, 500, circle.position.y, 250)
                if e.keyCode == 40
                    ay -= 0.05

                if e.keyCode == 32
                    DarkGrey.restartScene()

        restartScene: ->
            # TweenLite.to(Cfg, 10, { RADIUS: 1000 })

            # scene.remove circle
            # scene.remove city
            # scene.remove ambiant

            # circle = null
            # camera.lookAt scene.position

            # scene.add    city = DarkGrey.cityMesh()
            # scene.add    ambiant = DarkGrey.lights()

        initGui: ->
            gui = new dat.GUI
            gui.add(Cfg, 'TRANSITION_TARGET_SPEED', 0, 1).name('target speed').listen()
            gui.add(Cfg, 'LIGHT_SPEED', 0, 0.01).name('light speed').listen()
            gui.add(Cfg, 'RADIUS').name('Camera radius').listen()
            gui.addColor(Cfg, 'CITY_COLOR').name('City color')
            gui.addColor(Cfg, 'AMBIANT_COLOR').name('Ambiant color')
            gui.add(camera.position, 'y').name('Camera Y').listen()

        init: ->
            @events()
            @initGui()

        renderScene: ->
            scene.add light
            scene.add helper
            scene.add city = @cityMesh()
            scene.add ambiant = @lights()
            render()

    DarkGrey.init()
    DarkGrey.renderScene()
