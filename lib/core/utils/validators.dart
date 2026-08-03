String? validateRequired(String? value, {String field = '该字段'}) {
  if (value == null || value.trim().isEmpty) return '请填写$field';
  return null;
}

String? validateUsername(String? value) {
  final base = validateRequired(value, field: '用户名');
  if (base != null) return base;
  if (!RegExp(r'^[a-zA-Z0-9_.]{3,20}$').hasMatch(value!.trim())) {
    return '用户名需为 3-20 位字母/数字/下划线';
  }
  return null;
}

String? validatePassword(String? value, {String field = '密码'}) {
  final base = validateRequired(value, field: field);
  if (base != null) return base;
  if (value!.length < 6) return '$field至少 6 位';
  return null;
}

String? validateDisplayName(String? value) {
  final base = validateRequired(value, field: '姓名/昵称');
  if (base != null) return base;
  if (value!.trim().length > 20) return '姓名/昵称过长';
  return null;
}

String? validatePoints(String? value, {bool allowNegative = true}) {
  final base = validateRequired(value, field: '积分');
  if (base != null) return base;
  final n = int.tryParse(value!.trim());
  if (n == null) return '请输入整数';
  if (n == 0) return '积分变动不能为 0';
  if (!allowNegative && n < 0) return '积分不能为负';
  return null;
}

String? validateStock(String? value) {
  final base = validateRequired(value, field: '库存');
  if (base != null) return base;
  final n = int.tryParse(value!.trim());
  if (n == null || n < 0) return '请输入大于等于 0 的整数';
  return null;
}
