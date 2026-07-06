import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/walk_displacement.dart';
import '../models/walk_point.dart';

/// Projects a recorded walk onto any other place on Earth.
///
/// The walk is first converted to a portable shape: for every point, the
/// WGS84 *inverse* geodesic problem (Vincenty) gives its distance and initial
/// bearing from the walk's first point. Re-anchoring solves the *direct*
/// problem from a new origin with the same distance and (optionally rotated)
/// bearing. No flat-earth approximation is involved, so the result is valid
/// at any latitude — projecting a Champaign walk to Tromsø or Cape Town works
/// identically.
class WalkProjector {
  WalkProjector._();

  /// Vincenty on the WGS84 ellipsoid, used for the direct problem (offset).
  /// roundResult must be off: the default rounds distances to whole meters,
  /// which would visibly quantize a walk.
  ///
  /// NOTE: only [Distance.offset] respects the Vincenty calculator; the
  /// package's `bearing()` is a spherical great-circle formula, which is why
  /// the inverse problem is solved by [_inverse] below instead — mixing a
  /// spherical azimuth with an ellipsoidal direct step costs ~0.4 m per point
  /// at walking scale.
  static const _geodesic = Distance(roundResult: false);

  // WGS84 ellipsoid.
  static const _a = 6378137.0;
  static const _b = 6356752.314245;
  static const _f = 1 / 298.257223563;

  /// Inverse step: walk → origin-relative shape.
  /// The first point becomes (0 m, 0°) by construction.
  static List<WalkDisplacement> toShape(List<WalkPoint> points) {
    if (points.isEmpty) return const [];
    final origin = LatLng(points.first.latitude, points.first.longitude);

    return [
      for (final p in points)
        () {
          final (distance, bearing) =
              _inverse(origin, LatLng(p.latitude, p.longitude));
          return WalkDisplacement(
            distanceMeters: distance,
            bearingDegrees: bearing,
            timestamp: p.timestamp,
          );
        }(),
    ];
  }

  /// WGS84 Vincenty inverse: geodesic distance in meters and initial azimuth
  /// in degrees from [p1] to [p2]. Returns (0, 0) for coincident points.
  ///
  /// Vincenty's inverse iteration can fail to converge for near-antipodal
  /// pairs (~20,000 km apart) — irrelevant for points of a single walk.
  static (double, double) _inverse(LatLng p1, LatLng p2) {
    final l = p2.longitudeInRad - p1.longitudeInRad;
    final u1 = math.atan((1 - _f) * math.tan(p1.latitudeInRad));
    final u2 = math.atan((1 - _f) * math.tan(p2.latitudeInRad));
    final sinU1 = math.sin(u1), cosU1 = math.cos(u1);
    final sinU2 = math.sin(u2), cosU2 = math.cos(u2);

    double lambda = l, lambdaP;
    double sinLambda, cosLambda, sinSigma, cosSigma, sigma;
    double sinAlpha, cosSqAlpha, cos2SigmaM;
    var iterations = 200;

    do {
      sinLambda = math.sin(lambda);
      cosLambda = math.cos(lambda);
      sinSigma = math.sqrt(math.pow(cosU2 * sinLambda, 2) +
          math.pow(cosU1 * sinU2 - sinU1 * cosU2 * cosLambda, 2).toDouble());
      if (sinSigma == 0) return (0, 0); // coincident points

      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = math.atan2(sinSigma, cosSigma);
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cosSqAlpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM =
          cosSqAlpha == 0 ? 0 : cosSigma - 2 * sinU1 * sinU2 / cosSqAlpha;

      final c = _f / 16 * cosSqAlpha * (4 + _f * (4 - 3 * cosSqAlpha));
      lambdaP = lambda;
      lambda = l +
          (1 - c) *
              _f *
              sinAlpha *
              (sigma +
                  c *
                      sinSigma *
                      (cos2SigmaM +
                          c * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    } while ((lambda - lambdaP).abs() > 1e-12 && --iterations > 0);

    if (iterations == 0) {
      throw StateError('Vincenty inverse failed to converge');
    }

    final uSq = cosSqAlpha * (_a * _a - _b * _b) / (_b * _b);
    final aa =
        1 + uSq / 16384 * (4096 + uSq * (-768 + uSq * (320 - 175 * uSq)));
    final bb = uSq / 1024 * (256 + uSq * (-128 + uSq * (74 - 47 * uSq)));
    final deltaSigma = bb *
        sinSigma *
        (cos2SigmaM +
            bb /
                4 *
                (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                    bb /
                        6 *
                        cos2SigmaM *
                        (-3 + 4 * sinSigma * sinSigma) *
                        (-3 + 4 * cos2SigmaM * cos2SigmaM)));

    final distance = _b * aa * (sigma - deltaSigma);
    final alpha1 = math.atan2(
        cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda);
    return (distance, (radianToDeg(alpha1) + 360) % 360);
  }

  /// Direct step: shape + new origin (+ optional rotation about that origin,
  /// degrees clockwise) → projected walk.
  static List<WalkPoint> project(
    List<WalkDisplacement> shape,
    LatLng targetOrigin, {
    double rotationDegrees = 0,
  }) {
    return [
      for (final d in shape)
        () {
          final point = _geodesic.offset(
            targetOrigin,
            d.distanceMeters,
            d.bearingDegrees + rotationDegrees,
          );
          return WalkPoint(
            latitude: point.latitude,
            longitude: point.longitude,
            timestamp: d.timestamp,
          );
        }(),
    ];
  }
}
