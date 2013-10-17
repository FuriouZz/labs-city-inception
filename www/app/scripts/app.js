(function() {
  window.onload = function() {
    var Cfg, DarkGrey, PI, PI2, Themes, ambiant, animateCam, ax, ay, breath0, breath1, buildGeometry, camera, cameraAngle, cirTanAngle, circle, city, clearMask, composer, distanceCirle, effect, effectFilm, effectFilmBW, effectHBlur, effectVBlur, effectVignette, friction, inRadius, isAnimated, isTargeted, light, light2, lightAngle, limit, limitAcc, map_range, music, plane, projector, render, renderMaskInverse, renderModel, renderer, rtParams, scene, shaderVignette, skyboxMesh, targetPos, theme, vx, vy;
    Cfg = {
      LIGHT_SPEED: 0.0025,
      TRANSITION_TARGET_SPEED: 0.05,
      RADIUS: 245,
      CAMERA_Y: 500,
      CITY_COLOR: '#FFAA22',
      AMBIANT_COLOR: '#1A2024',
      SHADOW_BIAS: 0.0001,
      SHADOW_DARKNESS: 0.5
    };
    Themes = [
      {
        cityColor: '#C365AC',
        ambiantColor: '#3B2389',
        cityRadius: 50
      }, {
        cityColor: '#FFAA22',
        ambiantColor: '#20242A',
        cityRadius: 100
      }, {
        cityColor: '#21F2FF',
        ambiantColor: '#417EA7',
        cityRadius: 150
      }, {
        cityColor: '#00FFB3',
        ambiantColor: '#231137',
        cityRadius: 200
      }, {
        cityColor: '#FFFFFF',
        ambiantColor: '#484848',
        cityRadius: 250
      }, {
        cityColor: '#00FF96',
        ambiantColor: '#162A16',
        cityRadius: 300
      }
    ];
    console.log(Themes);
    PI = Math.PI;
    PI2 = Math.PI * 2;
    ax = 0;
    vx = 0;
    ay = 0;
    vy = 0;
    friction = 0.93;
    limit = 0.05;
    limitAcc = 0.005;
    city = null;
    ambiant = null;
    targetPos = new THREE.Vector3;
    plane = null;
    cameraAngle = 0;
    lightAngle = 100;
    circle = null;
    distanceCirle = 0;
    projector = new THREE.Projector;
    isTargeted = false;
    isAnimated = false;
    cirTanAngle = 0;
    theme = Themes[Math.floor(Math.random() * Themes.length)];
    scene = new THREE.Scene;
    scene.fog = new THREE.FogExp2(0xd0e0f0, 0.0020);
    camera = new THREE.PerspectiveCamera(75, window.innerWidth / window.innerHeight, 0.1, 10000);
    camera.position.y = 150;
    renderer = new THREE.WebGLRenderer({
      antialias: true
    });
    renderer.shadowMapEnabled = true;
    renderer.shadowMapSoft = true;
    renderer.shadowMapType = THREE.PCFShadowMap;
    renderer.setSize(window.innerWidth, window.innerHeight);
    document.body.appendChild(renderer.domElement);
    clearMask = new THREE.ClearMaskPass();
    renderModel = new THREE.RenderPass(scene, camera);
    renderMaskInverse = new THREE.MaskPass(scene, camera);
    renderMaskInverse.inverse = true;
    effectHBlur = new THREE.ShaderPass(THREE.HorizontalBlurShader);
    effectVBlur = new THREE.ShaderPass(THREE.VerticalBlurShader);
    effectHBlur.uniforms['h'].value = 2 / (window.innerWidth / 2);
    effectVBlur.uniforms['v'].value = 2 / (window.innerHeight / 2);
    effectFilm = new THREE.FilmPass(0.10, 0, 0, false);
    effectFilmBW = new THREE.FilmPass(0.35, 0.5, 2048, true);
    shaderVignette = THREE.VignetteShader;
    effectVignette = new THREE.ShaderPass(shaderVignette);
    effectVignette.uniforms["offset"].value = 0.5;
    effectVignette.uniforms["darkness"].value = 1.6;
    effect = new THREE.ShaderPass(THREE.BleachBypassShader);
    effectFilm.renderToScreen = true;
    effect.renderToScreen = true;
    rtParams = {
      minFilter: THREE.LinearFilter,
      magFilter: THREE.LinearFilter,
      format: THREE.RGBFormat,
      stencilBuffer: true
    };
    composer = new THREE.EffectComposer(renderer, new THREE.WebGLRenderTarget(window.innerWidth, window.innerWidth, rtParams));
    composer.addPass(renderModel);
    composer.addPass(effectFilm);
    light2 = new THREE.SpotLight(0xd0e0f0, 25, 0, PI / 16, 100);
    light2.position.y = 50;
    scene.add(light2);
    light = new THREE.SpotLight(0xFFFFFF, 4, 0, PI / 16, 500);
    light.position.set(0, Cfg.CAMERA_Y, 0);
    light.target.position.set(0, 0, 0);
    light.castShadow = true;
    light.shadowCameraNear = 700;
    light.shadowCameraFar = camera.far;
    light.shadowCameraFov = 50;
    light.shadowBias = Cfg.SHADOW_BIAS;
    light.shadowDarkness = Cfg.SHADOW_DARKNESS;
    light.shadowCameraRight = 5;
    light.shadowCameraLeft = -5;
    light.shadowCameraTop = 5;
    light.shadowCameraBottom = -5;
    light.shadowMapWidth = 2048;
    light.shadowMapHeight = 2048;
    skyboxMesh = new THREE.Mesh(new THREE.CubeGeometry(10000, 10000, 10000), new THREE.MeshPhongMaterial({
      color: 0xd0e0f0,
      side: THREE.BackSide
    }));
    scene.add(skyboxMesh);
    music = new Howl({
      urls: ['plane.mp3'],
      volume: 0.5,
      loop: true
    }).play();
    breath0 = new Howl({
      urls: ['breath0.wav'],
      volume: 0.25
    });
    breath1 = new Howl({
      urls: ['wind.mp3'],
      volume: 0.25
    });
    map_range = function(value, low1, high1, low2, high2) {
      return low2 + (high2 - low2) * (value - low1) / (high1 - low1);
    };
    inRadius = function(obj1, obj2) {
      var obj1Angle, obj2Angle;
      obj1Angle = Math.atan2(obj1.position.z, obj1.position.x);
      obj2Angle = Math.atan2(obj2.position.z, obj2.position.x);
      return obj1Angle > obj2Angle - PI / 8 && obj1Angle < obj2Angle + PI / 8;
    };
    render = function() {
      requestAnimationFrame(render);
      if (!(isTargeted && (isAnimated || inRadius(camera, circle)))) {
        ax = Math.max(Math.min(limitAcc, ax), -limitAcc);
        ax *= friction;
        vx *= friction;
        vx += ax;
        vx = Math.max(Math.min(limit, vx), -limit);
        cameraAngle += vx;
        camera.position.x = 1.5 * Cfg.RADIUS * Math.cos(cameraAngle);
        camera.position.z = 1.5 * Cfg.RADIUS * Math.sin(cameraAngle);
        ay = Math.max(Math.min(5, ay), -5);
        ay *= friction;
        vy *= friction;
        vy += ay;
        vy = Math.max(Math.min(5, vy), -5);
        camera.position.y += vy;
      }
      lightAngle += Cfg.LIGHT_SPEED;
      light.position.x = 700 * Math.cos(lightAngle);
      light.position.z = 700 * Math.sin(lightAngle);
      light.position.y = 500;
      if (isTargeted || (!isTargeted && inRadius(camera, circle))) {
        targetPos.x += (circle.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED;
        targetPos.y += (circle.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED;
        targetPos.z += (circle.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED;
      } else {
        targetPos.x += (scene.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED;
        targetPos.y += (scene.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED;
        targetPos.z += (scene.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED;
      }
      if (isTargeted && !inRadius(camera, circle)) {
        ax += 0.05;
      } else if (isTargeted && inRadius(camera, circle) && !isAnimated) {
        ax = 0;
        isAnimated = true;
        animateCam();
      }
      camera.lookAt(targetPos);
      renderer.clear();
      return composer.render(0.01);
    };
    animateCam = function() {
      return TweenMax.to(circle.position, 1, {
        x: plane.position.x,
        y: plane.position.y + 300,
        z: plane.position.z,
        ease: Expo.easeInOut,
        delay: 0.25,
        onStart: function() {
          breath1.stop().fadeIn(0.1, 1000);
          return breath1.play().fadeOut(0, 1000);
        },
        onComplete: function() {
          return TweenMax.to(camera.position, 1, {
            x: circle.position.x + 25,
            y: circle.position.y + 25,
            z: circle.position.z - 25,
            ease: Expo.easeInOut,
            delay: 0.5,
            onStart: function() {
              breath0.stop().fadeIn(0.5, 1000);
              return breath0.play().fadeOut(0, 1000);
            },
            onComplete: function() {
              scene.add(plane);
              return TweenMax.to(circle.position, 1, {
                y: -100,
                ease: Expo.easeInOut,
                delay: 0.25,
                onStart: function() {
                  breath1.stop().fadeIn(0.1, 1000);
                  return breath1.play().fadeOut(0, 1000);
                },
                onComplete: function() {
                  return TweenMax.to(camera.position, 0.5, {
                    delay: 0.25,
                    x: circle.position.x,
                    y: plane.position.y + 1,
                    z: circle.position.z,
                    ease: Expo.easeInOut,
                    onStart: function() {
                      breath0.stop().fadeIn(0.5, 1000);
                      return breath0.play().fadeOut(0, 1000);
                    },
                    onComplete: function() {
                      return DarkGrey.restartScene();
                    }
                  });
                }
              });
            }
          });
        }
      });
    };
    buildGeometry = new THREE.CubeGeometry(1, 1, 1);
    buildGeometry.applyMatrix(new THREE.Matrix4().makeTranslation(0, 0.5, 0));
    DarkGrey = {
      buildingMesh: function(i) {
        var circleColor, mesh, targetAngle;
        targetAngle = Math.random() * PI2;
        mesh = new THREE.Mesh(buildGeometry);
        mesh.position.x = Math.cos(targetAngle) * (Math.random() + 0.075) * theme.cityRadius;
        mesh.position.z = Math.sin(targetAngle) * (Math.random() + 0.075) * theme.cityRadius;
        mesh.position.y = 0;
        mesh.scale.x = Math.random() * Math.random() * Math.random() * Math.random() * 50 + 10;
        mesh.scale.z = mesh.scale.x;
        mesh.scale.y = (Math.random() * Math.random() * Math.random() * mesh.scale.x) * 8 + 8;
        if (mesh.position.distanceTo(scene.position) > theme.cityRadius - 50 && !circle) {
          console.log(theme.cityRadius);
          plane = new THREE.Mesh(new THREE.PlaneGeometry(50, 50), new THREE.MeshBasicMaterial({
            color: 0xd0e0f0
          }));
          plane.position.y = 2;
          plane.rotation.x = -PI / 2;
          circleColor = new THREE.Color(Cfg.CITY_COLOR);
          circle = new THREE.Mesh(new THREE.SphereGeometry(2.5, 100, 100), new THREE.MeshLambertMaterial({
            color: circleColor.getHex()
          }));
          circle.position.x = mesh.position.x;
          circle.position.z = mesh.position.z;
          circle.position.y = mesh.position.y + 100;
          circle.castShadow = true;
          scene.add(circle);
          distanceCirle = circle.position.distanceTo(scene.position);
        }
        return mesh;
      },
      buildSquare: function(i) {
        var geometry, mesh, scale, targetAngle;
        targetAngle = Math.random() * PI2;
        geometry = new THREE.CubeGeometry(1, 1, 1);
        geometry.applyMatrix(new THREE.Matrix4().makeTranslation(0, -0.5, 0));
        mesh = new THREE.Mesh(geometry);
        mesh.position.x = Math.cos(targetAngle) * 600;
        mesh.position.z = Math.sin(targetAngle) * 600;
        mesh.position.y = 400 * Math.random() + 100;
        scale = Math.random() * Math.random() * 400;
        mesh.scale.set(scale, scale, scale);
        mesh.rotation.x = Math.random() * PI2;
        mesh.rotation.y = Math.random() * PI2;
        mesh.rotation.z = Math.random() * PI2;
        return mesh;
      },
      cityMesh: function() {
        var cityGeometry, cityMesh, decoGeometry, ground, i, planeColor, planeGeometry, planeMaterial, _i, _j;
        planeColor = new THREE.Color(Cfg.CITY_COLOR);
        planeGeometry = new THREE.PlaneGeometry(400, 400);
        planeGeometry.verticesNeedUpdate = true;
        planeMaterial = new THREE.MeshPhongMaterial({
          color: planeColor.getHex()
        });
        planeMaterial.ambiant = planeMaterial.color;
        ground = new THREE.Mesh(planeGeometry, planeMaterial);
        ground.rotation.x = -PI / 2;
        ground.scale.set(100, 100, 100);
        ground.castShadow = true;
        ground.receiveShadow = true;
        cityGeometry = new THREE.Geometry;
        for (i = _i = 0; _i < 600; i = ++_i) {
          THREE.GeometryUtils.merge(cityGeometry, this.buildingMesh(i));
        }
        decoGeometry = new THREE.Geometry;
        for (i = _j = 0; _j < 50; i = ++_j) {
          THREE.GeometryUtils.merge(decoGeometry, this.buildSquare());
        }
        THREE.GeometryUtils.merge(cityGeometry, ground);
        THREE.GeometryUtils.merge(cityGeometry, decoGeometry);
        cityMesh = new THREE.Mesh(cityGeometry, planeMaterial);
        cityMesh.scale.set(1, 1, 1);
        cityMesh.castShadow = true;
        cityMesh.receiveShadow = true;
        return cityMesh;
      },
      lights: function() {
        var ambiantColor, ambient;
        ambiantColor = new THREE.Color(Cfg.AMBIANT_COLOR);
        return ambient = new THREE.AmbientLight(ambiantColor.getHex());
      },
      events: function() {
        document.addEventListener('keydown', function(e) {
          if (!isTargeted) {
            if (e.keyCode === 37) {
              ax += 0.001;
            }
            if (e.keyCode === 39) {
              ax -= 0.001;
            }
            if (e.keyCode === 38) {
              ay += 0.05;
            }
            if (e.keyCode === 40) {
              ay -= 0.05;
            }
            if (e.keyCode === 32) {
              return isTargeted = true;
            }
          }
        });
        return document.addEventListener('click', function(event) {
          event.preventDefault();
          return isTargeted = true;
        });
      },
      restartScene: function() {
        breath0.fadeOut(0, 2000, function() {
          return breath0.stop();
        });
        breath1.fadeOut(0, 2000, function() {
          return breath1.stop();
        });
        camera.position.set(5000, 2000, 5000);
        isTargeted = false;
        isAnimated = false;
        theme = Themes[Math.floor(Math.random() * Themes.length)];
        Cfg.CITY_COLOR = theme.cityColor;
        Cfg.AMBIANT_COLOR = theme.ambiantColor;
        scene.remove(plane);
        scene.remove(circle);
        scene.remove(city);
        scene.remove(ambiant);
        circle = null;
        camera.lookAt(scene.position);
        scene.add(city = DarkGrey.cityMesh());
        scene.add(ambiant = DarkGrey.lights());
        TweenMax.to(camera.position, 1.5, {
          y: 150
        });
        return TweenMax.to(Cfg, 1.5, {
          RADIUS: 245
        });
      },
      initGui: function() {
        var gui;
        gui = new dat.GUI;
        gui.add(Cfg, 'TRANSITION_TARGET_SPEED', 0, 1).name('target speed').listen();
        gui.add(Cfg, 'LIGHT_SPEED', 0, 0.01).name('light speed').listen();
        gui.add(Cfg, 'RADIUS').name('Camera radius').listen();
        gui.addColor(Cfg, 'CITY_COLOR').name('City color').listen();
        gui.addColor(Cfg, 'AMBIANT_COLOR').name('Ambiant color').listen();
        gui.add(camera.position, 'y').name('Camera Y').listen();
        gui.add(Cfg, 'SHADOW_BIAS').name('Shadow bias');
        return gui.add(Cfg, 'SHADOW_DARKNESS').name('Shadow darkness');
      },
      init: function() {
        this.events();
        return this.initGui();
      },
      renderScene: function() {
        scene.add(light);
        scene.add(city = this.cityMesh());
        scene.add(ambiant = this.lights());
        return render();
      }
    };
    DarkGrey.init();
    return DarkGrey.renderScene();
  };

}).call(this);
