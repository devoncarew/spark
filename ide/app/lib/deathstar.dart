
import 'dart:html' show Point;
import 'dart:math' show Random;

class SectorDefense {
  final DeathStar deathStar;

  SectorDefense() : deathStar = new DeathStar();

  bool destroyStation(XWing xwing) {
    xwing.fire(deathStar);
    return deathStar.isDestroyed;
  }
}

class DeathStar {
  Point _coords;
  bool _destroyed = false;

  DeathStar() {
    _coords = new Point(0, 0);
  }

  Point get exhaustPortCoordinates => _coords;

  void destroy() {
    _destroyed = true;
  }

  bool get isDestroyed => _destroyed;
}

class XWing {
  XWing();

  void fire(DeathStar deathStar) {
    if (isOnTarget(deathStar)) {
      deathStar.destroy();
    }
  }
  
  bool isOnTarget(DeathStar deathStar) {
    return new Random().nextInt(10) >= 9;
  }
}
