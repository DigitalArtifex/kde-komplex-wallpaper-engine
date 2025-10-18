// https://www.shadertoy.com/view/l3dyRB

// Ruido pseudo-aleatorio basado en hash
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Función para calcular el mapa de normales a partir del mapa de altura
vec3 calculateNormal(vec2 uv, float heightScale) {
    float d = 1.0 / iResolution.x; // Delta basado en la resolución
    float hL = texture(iChannel0, uv - vec2(d, 0.0)).r * heightScale; // Izquierda
    float hR = texture(iChannel0, uv + vec2(d, 0.0)).r * heightScale; // Derecha
    float hT = texture(iChannel0, uv - vec2(0.0, d)).r * heightScale; // Arriba
    float hB = texture(iChannel0, uv + vec2(0.0, d)).r * heightScale; // Abajo

    // Normales derivadas
    vec3 normal = normalize(vec3(hL - hR, hT - hB, 1.0));
    return normal;
}

// Cálculo de Ambient Occlusion (AO)
float calculateAO(vec2 uv, float height, float radius, int samples) {
    float ao = 0.0;
    float angleStep = 6.28318530718 / float(samples); // Paso angular (2*PI / muestras)

    for (int i = 0; i < samples; i++) {
        float angle = float(i) * angleStep;
        vec2 offset = vec2(cos(angle), sin(angle)) * radius;

        // Altura en el punto de muestra
        float sampleHeight = texture(iChannel0, uv + offset).r;
        float diff = height - sampleHeight;

        // Incremento AO si el punto de muestra está por debajo
        ao += smoothstep(0.0, radius, diff);
    }

    // Normalizar el AO (invertido para que las áreas ocluidas sean más oscuras)
    return 1.0 - ao / float(samples);
}

// Calcular sombras fuertes basadas en luminancia
float calculateShadows(vec2 uv, float lowerThreshold, float upperThreshold) {
    vec3 videoColor = texture(iChannel0, uv).rgb;
    float luminance = dot(videoColor, vec3(0.299, 0.587, 0.114)); // Luminancia

    // Máscara de sombras fuertes
    return smoothstep(upperThreshold, lowerThreshold, luminance);
}

// Luz puntual con PBR (metalness y roughness)
float pointLight(vec3 normal, vec2 uv, vec2 lightPos, vec3 lightDir, float intensity, float roughness, float metalness) {
    vec2 toLight = lightPos - uv;
    float distance = length(toLight);
    vec3 dir = normalize(vec3(toLight, 0.5)); // Dirección ajustada

    // Atenuación
    float attenuation = intensity / (1.0 + distance * distance);

    // Especularidad controlada por PBR
    vec3 halfVector = normalize(dir + vec3(0.0, 0.0, 1.0));
    float NdotH = max(dot(normal, halfVector), 0.0);
    float specular = pow(NdotH, 1.0 / (roughness + 0.001)) * (1.0 - metalness);

    // Difuso y especular
    float diffuse = max(dot(normal, dir), 0.0) * attenuation;
    return diffuse + specular * attenuation;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord.xy / iResolution.xy; // Coordenadas normalizadas

    // Luminancia del video como mapa de altura
    vec3 videoColor = texture(iChannel0, uv).rgb;
    float height = dot(videoColor, vec3(0.299, 0.587, 0.114)); // Altura basada en luminancia

    // Generar normales
    vec3 normal = calculateNormal(uv, 18.0);

    // Calcular AO
    float aoRadius = 0.02;       // Radio del AO
    int aoSamples = 32;          // Número de muestras para AO
    float aoIntensity = 0.4;     // Intensidad del AO (0 = desactivado, 1 = máximo)
    float ao = calculateAO(uv, height, aoRadius, aoSamples) * aoIntensity;

    // Calcular sombras fuertes
    float lowerThreshold = 0.2;  // Inicio de sombras fuertes
    float upperThreshold = 0.1;  // Fin de sombras fuertes
    float shadowIntensity = 0.3; // Intensidad de sombras fuertes
    float shadows = calculateShadows(uv, lowerThreshold, upperThreshold) * shadowIntensity;

    // Configuración de luces
    vec2 light1Pos = vec2(0.1, 0.9); // Superior izquierda
    vec2 light2Pos = vec2(0.9, 0.1); // Inferior derecha
    vec3 light1Dir = vec3(0.0, -1.0, 0.5); // Rotación fija
    vec3 light2Dir = vec3(0.0, 1.0, 0.5);

    // Parámetros de luz y material
    float intensity1 = 2.7;
    float intensity2 = 0.4;
    float roughness = 0.4; // Entre 0 y 1
    float metalness = 0.5; // Entre 0 y 1
    vec3 materialColor = vec3(0.5, 0.4, 0.3); // Color base del material

    // Calcular iluminación de ambas luces
    float light1 = pointLight(normal, uv, light1Pos, light1Dir, intensity1, roughness, metalness);
    float light2 = pointLight(normal, uv, light2Pos, light2Dir, intensity2, roughness, metalness);

    // Aplicar AO y sombras al material
    float combinedAO = mix(1.0, ao, aoIntensity);
    float combinedShadows = mix(1.0, shadows, shadowIntensity);

    // Mezclar iluminación con AO, sombras y material
    vec3 finalMaterial = (light1 + light2) * materialColor * combinedAO * combinedShadows;

    // Mezcla con el video original (10%)
    vec3 finalColor = mix(finalMaterial, videoColor, 0.1);

    fragColor = vec4(finalColor, 1.0);
}

