#pragma once
#include <cmath>
#include <vector>
#include <CoreGraphics/CoreGraphics.h>

struct Vector2D {
    float x, y;
    Vector2D() : x(0), y(0) {}
    Vector2D(float _x, float _y) : x(_x), y(_y) {}

    Vector2D operator+(const Vector2D& o) const { return Vector2D(x + o.x, y + o.y); }
    Vector2D operator-(const Vector2D& o) const { return Vector2D(x - o.x, y - o.y); }
    Vector2D operator*(float s) const { return Vector2D(x * s, y * s); }
    float dot(const Vector2D& o) const { return x * o.x + y * o.y; }
    float lengthSq() const { return x * x + y * y; }
    float length() const { return std::sqrt(lengthSq()); }
    Vector2D normalized() const {
        float len = length();
        return len > 0.0001f ? Vector2D(x / len, y / len) : Vector2D(0, 0);
    }
};

struct RaycastResult {
    bool hitBall;
    int hitBallId;
    Vector2D hitPoint;
    Vector2D reflectDir;
    Vector2D targetBallDir;
};

class BilliardPhysics {
public:
    static constexpr float BALL_RADIUS = 15.0f; // Game ki ball radius units me adjust karein

    // 1. Ray vs Table Cushion Check
    static bool RaycastCushion(const Vector2D& origin, const Vector2D& dir, 
                               float minX, float maxX, float minY, float maxY, 
                               Vector2D& outHit, Vector2D& outReflect) 
    {
        float tMin = 1e9f;
        Vector2D bestNormal(0, 0);

        // Right Wall (maxX)
        if (dir.x > 0) {
            float t = (maxX - origin.x) / dir.x;
            if (t > 0.01f && t < tMin) { tMin = t; bestNormal = Vector2D(-1, 0); }
        }
        // Left Wall (minX)
        if (dir.x < 0) {
            float t = (minX - origin.x) / dir.x;
            if (t > 0.01f && t < tMin) { tMin = t; bestNormal = Vector2D(1, 0); }
        }
        // Top Wall (maxY)
        if (dir.y > 0) {
            float t = (maxY - origin.y) / dir.y;
            if (t > 0.01f && t < tMin) { tMin = t; bestNormal = Vector2D(0, -1); }
        }
        // Bottom Wall (minY)
        if (dir.y < 0) {
            float t = (minY - origin.y) / dir.y;
            if (t > 0.01f && t < tMin) { tMin = t; bestNormal = Vector2D(0, 1); }
        }

        if (tMin < 1e8f) {
            outHit = origin + dir * tMin;
            // Vector Reflection: R = V - 2(V·N)N
            outReflect = dir - bestNormal * (2.0f * dir.dot(bestNormal));
            return true;
        }
        return false;
    }

    // 2. Ray vs Target Ball Collision Check
    static bool RaycastBall(const Vector2D& origin, const Vector2D& dir, 
                            const std::vector<std::pair<int, Vector2D>>& targetBalls, 
                            RaycastResult& result) 
    {
        float closestDist = 1e9f;
        bool found = false;

        for (const auto& target : targetBalls) {
            Vector2D ballPos = target.second;
            Vector2D oc = ballPos - origin;
            float proj = oc.dot(dir);

            if (proj < 0) continue; // Piche hai ball

            float perpDistSq = oc.lengthSq() - (proj * proj);
            float collisionRadius = 2.0f * BALL_RADIUS;

            if (perpDistSq <= (collisionRadius * collisionRadius)) {
                float d = std::sqrt((collisionRadius * collisionRadius) - perpDistSq);
                float t = proj - d;

                if (t > 0.01f && t < closestDist) {
                    closestDist = t;
                    found = true;
                    result.hitBall = true;
                    result.hitBallId = target.first;
                    result.hitPoint = origin + dir * t;
                    
                    // Target ball collision normal aur directions
                    Vector2D impactNormal = (ballPos - result.hitPoint).normalized();
                    result.targetBallDir = impactNormal;
                    
                    // Cue ball deflection (90-degree tangent)
                    Vector2D tangent(-impactNormal.y, impactNormal.x);
                    result.reflectDir = tangent * dir.dot(tangent);
                }
            }
        }
        return found;
    }

    // 3. Multi-Bounce Loop (Calculate Full Path)
    static std::vector<std::pair<Vector2D, Vector2D>> CalculateTrajectory(
        Vector2D cuePos, float aimAngle, 
        float minX, float maxX, float minY, float maxY,
        const std::vector<std::pair<int, Vector2D>>& activeBalls,
        int maxBounces = 5) 
    {
        std::vector<std::pair<Vector2D, Vector2D>> lineSegments;
        Vector2D currentOrigin = cuePos;
        Vector2D currentDir(std::cos(aimAngle), std::sin(aimAngle));

        for (int i = 0; i < maxBounces; i++) {
            RaycastResult ballHit{};
            bool hitTarget = RaycastBall(currentOrigin, currentDir, activeBalls, ballHit);

            Vector2D wallHit, wallReflect;
            bool hitWall = RaycastCushion(currentOrigin, currentDir, minX, maxX, minY, maxY, wallHit, wallReflect);

            // Check kis point par pehle hit hua (Ball ya Wall)
            float distToBall = hitTarget ? (ballHit.hitPoint - currentOrigin).length() : 1e9f;
            float distToWall = hitWall ? (wallHit - currentOrigin).length() : 1e9f;

            if (hitTarget && distToBall < distToWall) {
                // Ball se takraya
                lineSegments.push_back({currentOrigin, ballHit.hitPoint});
                
                // Target ball ka outgoing path draw karne ke liye
                Vector2D targetEnd = ballHit.hitPoint + ballHit.targetBallDir * 300.0f;
                lineSegments.push_back({ballHit.hitPoint, targetEnd});
                break; // Collision ke baad main cue line stop
            } else if (hitWall) {
                // Cushion se takraya (Bounce)
                lineSegments.push_back({currentOrigin, wallHit});
                currentOrigin = wallHit;
                currentDir = wallReflect.normalized();
            } else {
                break;
            }
        }
        return lineSegments;
    }
};