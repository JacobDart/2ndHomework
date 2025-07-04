// dart:io는 파일을 읽거나 쓰고, 사용자 입력을 받는 데 사용하는 라이브러리입니다.
import 'dart:io';
// dart:math는 랜덤 값을 만들기 위해 사용하는 라이브러리입니다.
import 'dart:math';

// 캐릭터와 몬스터가 공통으로 가지는 특징을 추상 클래스로 정의하였습니다.
abstract class Unit {
  String name;
  int hp;
  int attackPower;
  int defense;

  Unit(this.name, this.hp, this.attackPower, this.defense);

  // 체력이 0보다 크면 살아있는 상태입니다.
  bool get isAlive => hp > 0;

  // 데미지를 받으면 체력이 줄어듭니다. 단, 0보다 작아지지는 않습니다.
  void takeDamage(int damage) {
    hp -= damage;
    if (hp < 0) hp = 0;
  }

  // 현재 상태를 출력하는 함수입니다. 자식 클래스에서 구체적으로 구현해야 합니다.
  void showStatus();
}

// 캐릭터 클래스는 Unit을 상속받아 만들어졌습니다.
class Character extends Unit {
  Character(String name, int hp, int attackPower, int defense)
      : super(name, hp, attackPower, defense);

  // 몬스터에게 공격을 가합니다.
  void attackMonster(Monster monster) {
    monster.takeDamage(attackPower);
    print('$name(이)가 ${monster.name}에게 $attackPower의 데미지를 입혔습니다.');
  }

  // 방어 시, 몬스터의 공격력에서 방어력을 뺀 만큼 체력을 회복합니다.
  void defend(int damageFromMonster) {
    int healAmount = max(0, damageFromMonster - defense);
    hp += healAmount;
    print('$name(이)가 방어하여 $healAmount 만큼 체력을 회복했습니다.');
  }

  // 캐릭터의 현재 상태를 출력합니다.
  @override
  void showStatus() {
    print('$name - 체력: $hp, 공격력: $attackPower, 방어력: $defense');
  }
}

// 몬스터 클래스도 Unit을 상속받아 만들어졌습니다.
class Monster extends Unit {
  // 생성자에서 공격력을 랜덤 값과 캐릭터의 방어력 중 큰 값으로 설정합니다.
  Monster(String name, int hp, int maxAttack, int playerDefense)
      : super(name, hp, max(maxAttack, playerDefense), 0);

  // 캐릭터에게 공격을 가합니다.
  void attackCharacter(Character character) {
    int damage = max(0, attackPower - character.defense);
    character.takeDamage(damage);
    print('$name(이)가 ${character.name}에게 $damage의 데미지를 입혔습니다.');
  }

  // 몬스터의 현재 상태를 출력합니다.
  @override
  void showStatus() {
    print('$name - 체력: $hp, 공격력: $attackPower');
  }
}

// 게임 전체의 흐름을 관리하는 클래스입니다.
class Game {
  late Character character; // 캐릭터는 게임 시작 시 생성됩니다.
  List<Monster> monsters = []; // 몬스터 목록입니다.
  int defeatedMonsters = 0; // 물리친 몬스터 수를 저장합니다.

  // 캐릭터의 스탯을 파일에서 불러오는 함수입니다.
  void loadCharacterStats(String filePath) {
    try {
      final contents = File(filePath).readAsStringSync(); // 파일 내용을 문자열로 읽습니다.
      final stats = contents.split(','); // 쉼표 기준으로 분리합니다.
      if (stats.length != 3) throw FormatException('형식이 잘못되었습니다.');

      // 사용자에게 캐릭터 이름을 입력받습니다.
      stdout.write('캐릭터 이름을 입력하세요: ');
      String? name = stdin.readLineSync();

      // 이름이 유효한지 검사합니다. (한글 또는 영문만 허용)
      if (name == null || name.trim().isEmpty || !RegExp(r'^[a-zA-Z가-힣]+$').hasMatch(name)) {
        print('잘못된 이름입니다. 한글 또는 영문만 입력 가능합니다.');
        exit(1);
      }

      // 캐릭터를 생성합니다.
      character = Character(name, int.parse(stats[0]), int.parse(stats[1]), int.parse(stats[2]));
    } catch (e) {
      print('캐릭터 데이터를 불러오는 데 실패했습니다: $e');
      exit(1);
    }
  }

  // 몬스터들의 정보를 파일에서 불러오는 함수입니다.
  void loadMonsterStats(String filePath) {
    try {
      final lines = File(filePath).readAsLinesSync(); // 한 줄씩 읽어옵니다.
      for (var line in lines) {
        final data = line.split(',');
        if (data.length != 3) throw FormatException('몬스터 데이터 형식이 잘못되었습니다.');
        monsters.add(Monster(
          data[0],
          int.parse(data[1]),
          int.parse(data[2]),
          character.defense,
        ));
      }
    } catch (e) {
      print('몬스터 데이터를 불러오는 데 실패했습니다: $e');
      exit(1);
    }
  }

  // 몬스터 리스트 중 하나를 랜덤으로 가져오는 함수입니다.
  Monster getRandomMonster() {
    final random = Random();
    return monsters[random.nextInt(monsters.length)];
  }

  // 캐릭터와 몬스터가 한 번 전투를 벌이는 함수입니다.
  void battle(Monster monster) {
    print('\n[전투 시작] ${monster.name} 등장!\n');
    while (character.isAlive && monster.isAlive) {
      character.showStatus();
      monster.showStatus();

      stdout.write('행동 선택 (1: 공격, 2: 방어): ');
      String? input = stdin.readLineSync();

      if (input == '1') {
        character.attackMonster(monster);
      } else if (input == '2') {
        // 방어는 몬스터의 공격을 받은 뒤에 체력을 회복합니다.
        monster.attackCharacter(character);
        character.defend(monster.attackPower);
        continue;
      } else {
        print('잘못된 입력입니다. 다시 선택해주세요.');
        continue;
      }

      // 몬스터가 살아 있다면 공격을 수행합니다.
      if (monster.isAlive) {
        monster.attackCharacter(character);
      }
    }

    // 몬스터를 물리쳤을 경우 처리
    if (character.isAlive) {
      print('${monster.name} 처치 완료!');
      monsters.remove(monster);
      defeatedMonsters++;
    }
  }

  // 게임을 시작하고, 모든 진행을 담당하는 함수입니다.
  void startGame() {
    print('게임을 시작합니다!\n');

    while (character.isAlive && defeatedMonsters < 3) {
      Monster monster = getRandomMonster(); // 랜덤으로 몬스터 등장
      battle(monster); // 전투 시작

      if (defeatedMonsters >= 3) {
        print('🎉 모든 몬스터를 물리쳤습니다! 게임에서 승리하셨습니다.');
        _saveResult('승리');
        break;
      }

      if (!character.isAlive) {
        print('💀 캐릭터가 사망했습니다. 게임 오버입니다.');
        _saveResult('패배');
        break;
      }

      stdout.write('다음 몬스터와 싸우시겠습니까? (y/n): ');
      String? input = stdin.readLineSync();
      if (input?.toLowerCase() != 'y') {
        _saveResult('중단');
        break;
      }
    }
  }

  // 게임 결과를 파일로 저장하는 함수입니다.
  void _saveResult(String result) {
    stdout.write('결과를 저장하시겠습니까? (y/n): ');
    String? input = stdin.readLineSync();
    if (input?.toLowerCase() == 'y') {
      final resultData = '${character.name}, ${character.hp}, $result';
      File('result.txt').writeAsStringSync(resultData);
      print('결과가 result.txt 파일에 저장되었습니다.');
    }
  }
}

// 프로그램이 시작되는 메인 함수입니다.
void main() {
  Game game = Game();
  game.loadCharacterStats('characters.txt');
  game.loadMonsterStats('monsters.txt');
  game.startGame();
}
