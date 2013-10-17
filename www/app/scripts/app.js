(function() {
  window.onload = function() {
    var Cfg, Colors, DarkGrey, PI, PI2, ambiant, ax, ay, buildGeometry, camera, cameraAngle, circle, city, distanceCirle, friction, light, lightAngle, limit, limitAcc, map_range, plane, projector, render, renderer, scene, targetPos, targeted, vx, vy;
    Cfg = {
      LIGHT_SPEED: 0.0025,
      TRANSITION_TARGET_SPEED: 0.05,
      RADIUS: 245,
      CAMERA_Y: 500,
      CITY_COLOR: '#FFAA22',
      AMBIANT_COLOR: '#1A2024'
    };
    Colors = [['#C365AC', '#3B2389'], ['#FFAA22', '#20242A'], ['#21F2FF', '#417EA7'], ['#21F2FF', '#231137'], ['#FFFFFF', '#484848'], ['#00FF96', '#162A16']];
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
    scene = new THREE.Scene;
    scene.fog = new THREE.FogExp2(0xd0e0f0, 0.0015);
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
    light = new THREE.SpotLight(0xFFFFFF, 4, 0, PI / 16, 500);
    light.position.set(0, Cfg.CAMERA_Y, 0);
    light.target.position.set(0, 0, 0);
    light.castShadow = true;
    light.shadowCameraNear = 700;
    light.shadowCameraFar = camera.far;
    light.shadowCameraFov = 50;
    light.shadowBias = 0.0001;
    light.shadowDarkness = 0.5;
    light.shadowMapWidth = 1024;
    light.shadowMapHeight = 1024;
    targetPos = new THREE.Vector3;
    plane = null;
    cameraAngle = 0;
    lightAngle = 100;
    circle = null;
    distanceCirle = 0;
    projector = new THREE.Projector;
    targeted = false;
    map_range = function(value, low1, high1, low2, high2) {
      return low2 + (high2 - low2) * (value - low1) / (high1 - low1);
    };
    render = function() {
      var camTanAngle, cirTanAngle;
      requestAnimationFrame(render);
      if (!targeted) {
        ax = Math.max(Math.min(limitAcc, ax), -limitAcc);
        ax *= friction;
        vx *= friction;
        vx += ax;
        vx = Math.max(Math.min(limit, vx), -limit);
        cameraAngle += vx;
        camera.position.x = 1.5 * Cfg.RADIUS * Math.cos(cameraAngle);
        camera.position.z = 1.5 * Cfg.RADIUS * Math.sin(cameraAngle);
      }
      ay = Math.max(Math.min(5, ay), -5);
      ay *= friction;
      vy *= friction;
      vy += ay;
      vy = Math.max(Math.min(5, vy), -5);
      camera.position.y += vy;
      lightAngle += Cfg.LIGHT_SPEED;
      light.position.x = 700 * Math.cos(lightAngle);
      light.position.z = 700 * Math.sin(lightAngle);
      light.position.y = 500;
      camTanAngle = Math.atan2(camera.position.z, camera.position.x);
      cirTanAngle = Math.atan2(circle.position.z, circle.position.x);
      if (targeted || (camTanAngle > cirTanAngle - PI / 8 && camTanAngle < cirTanAngle + PI / 8)) {
        targetPos.x += (circle.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED;
        targetPos.y += (circle.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED;
        targetPos.z += (circle.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED;
      } else {
        targetPos.x += (scene.position.x - targetPos.x) * Cfg.TRANSITION_TARGET_SPEED;
        targetPos.y += (scene.position.y - targetPos.y) * Cfg.TRANSITION_TARGET_SPEED;
        targetPos.z += (scene.position.z - targetPos.z) * Cfg.TRANSITION_TARGET_SPEED;
      }
      camera.lookAt(targetPos);
      return renderer.render(scene, camera);
    };
    buildGeometry = new THREE.CubeGeometry(1, 1, 1);
    buildGeometry.applyMatrix(new THREE.Matrix4().makeTranslation(0, 0.5, 0));
    DarkGrey = {
      buildingMesh: function(i) {
        var circleColor, mesh, targetAngle;
        targetAngle = Math.random() * PI2;
        mesh = new THREE.Mesh(buildGeometry);
        mesh.position.x = Math.cos(targetAngle) * (Math.random() + 0.075) * 250;
        mesh.position.z = Math.sin(targetAngle) * (Math.random() + 0.075) * 250;
        mesh.position.y = Math.random() * PI2;
        mesh.scale.x = Math.random() * Math.random() * Math.random() * Math.random() * 50 + 10;
        mesh.scale.z = mesh.scale.x;
        mesh.scale.y = (Math.random() * Math.random() * Math.random() * mesh.scale.x) * 8 + 8;
        if (mesh.position.distanceTo(scene.position) > 200 && !circle) {
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
      cityMesh: function() {
        var cityGeometry, cityMesh, ground, i, planeColor, planeGeometry, planeMaterial, _i;
        planeColor = new THREE.Color(Cfg.CITY_COLOR);
        planeGeometry = new THREE.PlaneGeometry(400, 400);
        planeGeometry.verticesNeedUpdate = true;
        planeMaterial = new THREE.MeshPhongMaterial({
          color: planeColor.getHex()
        });
        planeMaterial.ambiant = planeMaterial.color;
        ground = new THREE.Mesh(planeGeometry, planeMaterial);
        ground.rotation.x = -PI / 2;
        ground.scale.set(2, 2, 2);
        ground.castShadow = true;
        ground.receiveShadow = true;
        cityGeometry = new THREE.Geometry;
        for (i = _i = 0; _i < 600; i = ++_i) {
          THREE.GeometryUtils.merge(cityGeometry, this.buildingMesh(i));
        }
        THREE.GeometryUtils.merge(cityGeometry, ground);
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
            return DarkGrey.restartScene();
          }
        });
        return document.addEventListener('click', function(event) {
          var intersects, raycaster, vector;
          event.preventDefault();
          vector = new THREE.Vector3((event.clientX / window.innerWidth) * 2 - 1, -(event.clientY / window.innerHeight) * 2 + 1, 0.5);
          projector.unprojectVector(vector, camera);
          raycaster = new THREE.Raycaster(camera.position, vector.sub(camera.position).normalize());
          intersects = raycaster.intersectObject(circle);
          if (intersects.length > 0) {
            targeted = true;
            return TweenMax.to(circle.position, 1, {
              x: plane.position.x,
              y: plane.position.y + 300,
              z: plane.position.z,
              delay: 1,
              onComplete: function() {
                return TweenMax.to(camera.position, 1, {
                  x: circle.position.x + 25,
                  y: circle.position.y + 25,
                  z: circle.position.z - 25,
                  ease: Expo.easeInOut,
                  delay: 0.5,
                  onComplete: function() {
                    scene.add(plane);
                    return TweenMax.to(circle.position, 1, {
                      y: -100,
                      delay: 0.25,
                      onComplete: function() {
                        return TweenMax.to(camera.position, 0.5, {
                          delay: 0.25,
                          x: circle.position.x,
                          y: plane.position.y + 1,
                          z: circle.position.z,
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
          }
        });
      },
      restartScene: function() {
        var clrs;
        camera.position.set(5000, 2000, 5000);
        targeted = false;
        clrs = Colors[Math.floor(Math.random() * Colors.length)];
        Cfg.CITY_COLOR = clrs[0];
        Cfg.AMBIANT_COLOR = clrs[1];
        scene.remove(plane);
        scene.remove(circle);
        scene.remove(city);
        scene.remove(ambiant);
        circle = null;
        camera.lookAt(scene.position);
        scene.add(city = DarkGrey.cityMesh());
        scene.add(ambiant = DarkGrey.lights());
        TweenMax.to(camera.position, 2, {
          y: 150
        });
        return TweenMax.to(Cfg, 2, {
          RADIUS: 245
        });
      },
      initGui: function() {
        var gui;
        gui = new dat.GUI;
        gui.add(Cfg, 'TRANSITION_TARGET_SPEED', 0, 1).name('target speed').listen();
        gui.add(Cfg, 'LIGHT_SPEED', 0, 0.01).name('light speed').listen();
        gui.add(Cfg, 'RADIUS').name('Camera radius').listen();
        gui.addColor(Cfg, 'CITY_COLOR').name('City color');
        gui.addColor(Cfg, 'AMBIANT_COLOR').name('Ambiant color');
        return gui.add(camera.position, 'y').name('Camera Y').listen();
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
