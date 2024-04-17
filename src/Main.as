// Settings

[Setting category="General" name="Render map border"]
bool S_renderBorder = true;

[Setting category="General" name="Render map border lines" hidden]
bool S_renderLines = true;

// Color / Line Properties
[Setting category="General" name="Line color" description="RGBA format for color setting"]
vec4 S_lineColor = vec4(1.f, 0.f, 0.f, 0.7f);

[Setting category="General" name="Use same color for all lines"]
bool S_useSameColorForAllLines = false;

[Setting category="General" name="Bottom line color" description="RGBA format for bottom line color"]
vec4 S_bottomLineColor = vec4(1.f, 0.f, 0.f, 0.5f);

[Setting category="General" name="Top line color" description="RGBA format for top line color"]
vec4 S_topLineColor = vec4(0.f, 1.f, 0.f, 0.5f);

[Setting category="General" name="Left line color" description="RGBA format for left line color"]
vec4 S_leftLineColor = vec4(0.f, 0.f, 1.f, 0.5f);

[Setting category="General" name="Right line color" description="RGBA format for right line color"]
vec4 S_rightLineColor = vec4(1.f, 1.f, 0.f, 0.5f);

[Setting category="General" name="Line thickness"]
float S_lineThickness = 2.0f;

// Distance based opacity
[Setting category="General" name="Distance based opacity when in round" description="Does not work when line optmization is enabled"]
bool S_opacityWhenNoPlayer = true;

[Setting category="General" name="Minimum opacity when using distance based opacity" min="0.1" max="1.0"]
float S_minOpacity = 0.1f;

[Setting category="General" name="Max distance for distance based opacity" min="0.1" max="2000.0"]
float S_maxDistance = 400.0f;

// Optimization
[Setting category="Optimization" name="Number of segments" min="1" max="500" description="Number of segments to split each line into. More segments = smoother lines, but more performance impact, most machines can 'handle' at least 500 segments, so that's where I've set the max, but you can override it if you want to by ctrl clicking the setting and typing in a new value manually."]
int S_numSegments = 150;

[Setting category="Optimization" name="Optimized number of segments" min="1" max="500" description="Number of segments to split each line into when player is far away"]
int S_optimizedNumSegments = 150;

[Setting category="Optimization" name="Enable line optimization" description="Enable optimized rendering for distant lines"]
bool S_enableLineOptimization = true;

[Setting category="Optimization" name="Distance threshold for optimization" min="100.0" max="2000.0" description="Distance at which line segment reduction starts" hidden]
float S_optimizationThreshold = S_maxDistance;


// Random color
[Setting category="Random" name="Use random color for entire lines (epelepsy warning)"]
bool S_useRandomColorForLines = false;


vec3 playerPos;

void RenderMenu() {
    if (UI::MenuItem("\\$2ca" + Icons::SquareO + "\\$z Enable map border lines", "", S_renderBorder)) {
        S_renderBorder = !S_renderBorder;
    }
}

void Main() {
    while (true) {
        onUpdateOrRenderFrame();
        yield();
    }
}

void onUpdateOrRenderFrame() {
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app is null) return;

    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    if (playground is null || playground.Arena.Players.Length == 0) { 
        playerPos = vec3(6847206875.0f, 6847206875.0f, 6847206875.0f); }
    else { 
    auto script = cast<CSmScriptPlayer>(playground.Arena.Players[0].ScriptAPI);
    playerPos = script.Position;
    }

    auto map = cast<CGameCtnChallenge@>(app.RootMap);
    if (map is null) return;

    vec3 mapSize = vec3(map.Size.x, 0, map.Size.z);
    renderMapBorder(mapSize, playerPos);
}

void renderMapBorder(const vec3 &in mapSize, const vec3 &in playerPos) {
    if (!S_renderBorder) return;

    vec3 actualMapSize = vec3(mapSize.x * 32, 8, mapSize.z * 32);

    vec3 bottomLeft = vec3(0, 8, 0);
    vec3 bottomRight = vec3(actualMapSize.x, 8, 0);
    vec3 topLeft = vec3(0, 8, actualMapSize.z);
    vec3 topRight = actualMapSize;

    if (S_renderLines) {
        renderSegmentedLine(bottomLeft, bottomRight, playerPos, S_useRandomColorForLines ? getRandomColor() : (S_useSameColorForAllLines ? S_lineColor : S_bottomLineColor), S_numSegments);
        renderSegmentedLine(bottomLeft, topLeft,     playerPos, S_useRandomColorForLines ? getRandomColor() : (S_useSameColorForAllLines ? S_lineColor : S_leftLineColor), S_numSegments);
        renderSegmentedLine(topRight,   bottomRight, playerPos, S_useRandomColorForLines ? getRandomColor() : (S_useSameColorForAllLines ? S_lineColor : S_rightLineColor), S_numSegments);
        renderSegmentedLine(topRight,   topLeft,     playerPos, S_useRandomColorForLines ? getRandomColor() : (S_useSameColorForAllLines ? S_lineColor : S_topLineColor), S_numSegments);
    }
}

void renderSegmentedLine(const vec3 &in startPos, const vec3 &in endPos, const vec3 &in playerPos, const vec4 &in lineColor, int baseNumSegments) {
    int segmentsToRender = baseNumSegments;
    float playerDistance = Math::Distance((startPos + endPos) * 0.5, playerPos);

    if (S_enableLineOptimization && playerDistance > S_optimizationThreshold) {
        segmentsToRender = S_optimizedNumSegments;
    }

    for (int i = 0; i < segmentsToRender; ++i) {
        float fraction = float(i) / segmentsToRender;
        float nextFraction = float(i + 1) / segmentsToRender;
        vec3 segmentStart = vec3(
            startPos.x + (endPos.x - startPos.x) * fraction,
            startPos.y + (endPos.y - startPos.y) * fraction,
            startPos.z + (endPos.z - startPos.z) * fraction
        );
        vec3 segmentEnd = vec3(
            startPos.x + (endPos.x - startPos.x) * nextFraction,
            startPos.y + (endPos.y - startPos.y) * nextFraction,
            startPos.z + (endPos.z - startPos.z) * nextFraction
        );

        if (S_enableLineOptimization) {
            float opacity = calculateOpacity(segmentStart, segmentEnd, playerPos);
            if (opacity > 0.1f) {
                renderLine(segmentStart, segmentEnd, playerPos, lineColor);
            }
        } else {
            renderLine(segmentStart, segmentEnd, playerPos, lineColor);
        }
    }
}

void renderLine(const vec3 &in startPos, const vec3 &in endPos, const vec3 &in playerPos, vec4 &in lineColor) {
    vec3 startScreenPos = Camera::ToScreen(startPos);
    vec3 endScreenPos = Camera::ToScreen(endPos);
    if (startScreenPos.z >= 0 || endScreenPos.z >= 0) return;

    float opacity = calculateOpacity(startPos, endPos, playerPos);
    vec4 colorWithOpacity = lineColor;
    colorWithOpacity.w *= opacity;

    nvg::BeginPath();
    nvg::MoveTo(startScreenPos.xy);
    nvg::LineTo(endScreenPos.xy);
    nvg::StrokeColor(colorWithOpacity);
    nvg::StrokeWidth(S_lineThickness);
    nvg::Stroke();
}

vec4 getRandomColor() {
    float r = Math::Rand(0.0, 1.0);
    float g = Math::Rand(0.0, 1.0);
    float b = Math::Rand(0.0, 1.0);
    float alpha = S_useSameColorForAllLines ? S_lineColor.w : 1.0;
    return vec4(r, g, b, alpha);
}

float calculateOpacity(const vec3 &in segmentStart, const vec3 &in segmentEnd, const vec3 &in playerPos) {
    if (playerPos.x == 6847206875.0f && playerPos.y == 6847206875.0f && playerPos.z == 6847206875.0f && S_opacityWhenNoPlayer) {
        return 0.85f;
    }

    vec3 midPoint = (segmentStart + segmentEnd) * 0.5;
    float distance = Math::Distance(midPoint, playerPos);
    const float maxDistance = S_maxDistance;
    const float minOpacity = S_minOpacity;
    float opacity = Math::Max(minOpacity, 1.0f - (distance / maxDistance));
    return opacity;
}