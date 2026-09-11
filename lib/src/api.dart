part of '../bazi_core.dart';

const invalidId = 255;
const wuxingNames = ['水', '木', '金', '土', '火'];
const relationKindMaskAll = 0xffff;

class TenGodId {
  static const biJian = 0;
  static const jieCai = 1;
  static const shiShen = 2;
  static const shangGuan = 3;
  static const pianCai = 4;
  static const zhengCai = 5;
  static const qiSha = 6;
  static const zhengGuan = 7;
  static const pianYin = 8;
  static const zhengYin = 9;
}

class LifeStageId {
  static const changSheng = 0;
  static const muYu = 1;
  static const guanDai = 2;
  static const linGuan = 3;
  static const diWang = 4;
  static const shuai = 5;
  static const bing = 6;
  static const si = 7;
  static const mu = 8;
  static const jue = 9;
  static const tai = 10;
  static const yang = 11;
}

class PillarSlot {
  static const year = 0;
  static const month = 1;
  static const day = 2;
  static const hour = 3;
  static const mingGong = 4;
  static const shenGong = 5;
  static const taiYuan = 6;
  static const taiXi = 7;
}

int pillarStem(int value) => ganzhiStem(value);
int pillarBranch(int value) => ganzhiBranch(value);
int pillarIndex(int value) => ganzhiIndex(value);
String pillarName(int value) => ganzhiName(value);
typedef PackedPillar = int;
typedef ShenShaBitset = BigInt;
const baziLiteInfo = {
  'status': 'rule core available',
  'corePackage': 'ephemeris_lite',
  'pillarEncoding': 'uint8-compatible: high nibble=stem, low nibble=branch',
};
const baziRuleInfo = {
  'packedPillar': 'high nibble=stem, low nibble=branch',
  'invalidId': invalidId,
  'hiddenStemCapacity': 3,
};
const shenShaInfo = {'stableIdCount': 66, 'representation': 'bigint bitset'};
BaziOptions resolveBaziOptions([BaziOptions? options]) =>
    options ?? BaziOptions();
