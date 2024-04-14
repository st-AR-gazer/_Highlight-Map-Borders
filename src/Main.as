// Settings
[Setting category="General" name="Render map border lines"]
bool S_renderLines = true;

[Setting category="General" name="Line color" description="RGBA format for color setting"]
vec4 S_lineColor = vec4(1.f, 0.f, 0.f, 0.9f);

[Setting category="General" name="Line thickness"]
float S_lineThickness = 2.0f;

[Setting category="General" name="Distance based opacity when in round"]
bool S_opacityWhenNoPlayer = true;

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
        playerPos = vec3(6847206875, 6847206875, 6847206875); }
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
    
    renderSegmentedLine(bottomLeft, bottomRight, playerPos, 40);
    renderSegmentedLine(bottomLeft, topLeft, playerPos, 40);
    renderSegmentedLine(topRight, bottomRight, playerPos, 40);
    renderSegmentedLine(topRight, topLeft, playerPos, 40);
}

void renderSegmentedLine(const vec3 &in startPos, const vec3 &in endPos, const vec3 &in playerPos, int segments) {
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
        renderLine(segmentStart, segmentEnd, playerPos);
    }
}

void renderLine(const vec3 &in startPos, const vec3 &in endPos, const vec3 &in playerPos) {
    vec3 startScreenPos = Camera::ToScreen(startPos);
    vec3 endScreenPos = Camera::ToScreen(endPos);
    if (startScreenPos.z >= 0 || endScreenPos.z >= 0) return;

    float opacity = calculateOpacity(startPos, endPos, playerPos);
    vec4 colorWithOpacity = S_lineColor;
    colorWithOpacity.w *= opacity;

    nvg::BeginPath();
    nvg::MoveTo(startScreenPos.xy);
    nvg::LineTo(endScreenPos.xy);
    nvg::StrokeColor(colorWithOpacity);
    nvg::StrokeWidth(S_lineThickness);
    nvg::Stroke();
}

float calculateOpacity(const vec3 &in segmentStart, const vec3 &in segmentEnd, const vec3 &in playerPos) {
    if (playerPos.x == 6847206875 && playerPos.y == 6847206875 && playerPos.z == 6847206875 && S_opacityWhenNoPlayer) {
        return 0.85f;
    }

    vec3 midPoint = (segmentStart + segmentEnd) * 0.5;
    float distance = Math::Distance(midPoint, playerPos);
    const float maxDistance = 400.0f;
    const float minOpacity = 0.1f;
    float opacity = Math::Max(minOpacity, 1.0f - (distance / maxDistance));
    return opacity;
}
