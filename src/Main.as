// Settings
[Setting category="General" name="Render map border lines"]
bool S_renderLines = true;

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

[Setting category="General" name="Distance based opacity when in round"]
bool S_opacityWhenNoPlayer = true;

[Setting category="General" name="Minimum opacity when using distance based opacity"]
float S_minOpacity = 0.1f;

[Setting category="General" name="Max distance for distance based opacity" min="0.0" max="2000.0"]
float S_maxDistance = 400.0f;

// Optimiation
[Setting category="General" name="Number of segments per line" min="1" max="100"]
int S_numSegments = 80;

[Setting category="Optimization" name="Dynamic segment optimization"]
bool S_dynamicSegmentOptimization = true;

[Setting category="Optimization" name="Segment optimization distance" min="100.0" max="2000.0"]
float S_optimizationDistance = 1000.0f;



vec3 playerPos;

void RenderMenu() {
    if (UI::MenuItem("\\$2ca" + Icons::SquareO + "\\$z Enable map border lines", "", S_renderLines)) {
        if (S_renderLines) {
            S_renderLines = false;
        } else {
            S_renderLines = true;
        }
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
    vec3 actualMapSize = vec3(mapSize.x * 32, 8, mapSize.z * 32);

    vec3 bottomLeft = vec3(0, 8, 0);
    vec3 bottomRight = vec3(actualMapSize.x, 8, 0);
    vec3 topLeft = vec3(0, 8, actualMapSize.z);
    vec3 topRight = actualMapSize;

    vec4 bottomColor = S_useSameColorForAllLines ? S_lineColor : S_bottomLineColor;
    vec4 topColor = S_useSameColorForAllLines ? S_lineColor : S_topLineColor;
    vec4 leftColor = S_useSameColorForAllLines ? S_lineColor : S_leftLineColor;
    vec4 rightColor = S_useSameColorForAllLines ? S_lineColor : S_rightLineColor;
    
    int segmentsToUse = calculateDynamicSegments(playerPos, actualMapSize, S_numSegments);
    
    renderSegmentedLine(bottomLeft, bottomRight, playerPos, bottomColor, segmentsToUse);
    renderSegmentedLine(bottomLeft, topLeft, playerPos, leftColor, segmentsToUse);
    renderSegmentedLine(topRight, bottomRight, playerPos, rightColor, segmentsToUse);
    renderSegmentedLine(topRight, topLeft, playerPos, topColor, segmentsToUse);
}

void renderSegmentedLine(const vec3 &in startPos, const vec3 &in endPos, const vec3 &in playerPos, const vec4 &in lineColor, int segments) {
    if (!S_renderLines) return;
    for (int i = 0; i < segments; ++i) {
        float fraction = float(i) / segments;
        float nextFraction = float(i + 1) / segments;
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
        renderLine(segmentStart, segmentEnd, playerPos, lineColor);
    }
}

void renderLine(const vec3 &in startPos, const vec3 &in endPos, const vec3 &in playerPos, const vec4 &in lineColor) {
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

const float USUAL_MAX_WIDTH = 48 * 32;
const float USUAL_MAX_HEIGHT = 40 * 8;
const float USUAL_MAX_DEPTH = 48 * 32;

int calculateDynamicSegments(const vec3 &in playerPos, const vec3 &in mapSize, int baseNumSegments) {
    vec3 centerOfMap = vec3(mapSize.x * 16, mapSize.y * 4, mapSize.z * 16);
    float playerDistanceToCenter = Math::Distance(playerPos, centerOfMap);

    if (mapSize.x * 32 > USUAL_MAX_WIDTH || mapSize.y * 8 > USUAL_MAX_HEIGHT || mapSize.z * 32 > USUAL_MAX_DEPTH) {
        return Math::Max(1, baseNumSegments / (int(Math::Ceil(playerDistanceToCenter / S_maxDistance))));
    } else if (S_dynamicSegmentOptimization) {
        if (playerDistanceToCenter > S_maxDistance) {
            return 1;
        }
        int reducedSegments = Math::Max(1, baseNumSegments / (int(Math::Ceil(playerDistanceToCenter / S_maxDistance))));
        return reducedSegments;
    }

    return baseNumSegments;
}
