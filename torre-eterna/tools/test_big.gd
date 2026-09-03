extends SceneTree

func _initialize() -> void:
	var falhas := 0
	falhas += _ok("from/to", absf(Big.to_f(Big.from(1234.5)) - 1234.5) < 1e-6)
	falhas += _ok("mul", absf(Big.mul(Big.from(2e10), Big.from(3e20)) - Big.from(6e30)) < 1e-9)
	falhas += _ok("div", absf(Big.div(Big.from(6e30), Big.from(3e20)) - Big.from(2e10)) < 1e-9)
	falhas += _ok("add basico", absf(Big.to_f(Big.add(Big.from(3.0), Big.from(7.0))) - 10.0) < 1e-9)
	falhas += _ok("add desigual", absf(Big.add(Big.from(1e30), Big.from(1.0)) - Big.from(1e30)) < 1e-12)
	falhas += _ok("sub", absf(Big.to_f(Big.sub(Big.from(10.0), Big.from(3.0))) - 7.0) < 1e-9)
	falhas += _ok("sub zero", Big.is_zero(Big.sub(Big.from(5.0), Big.from(5.0))))
	falhas += _ok("sub negativo vira zero", Big.is_zero(Big.sub(Big.from(3.0), Big.from(9.0))))
	falhas += _ok("zero mul", Big.is_zero(Big.mul(Big.ZERO, Big.from(1e50))))
	falhas += _ok("zero add", absf(Big.add(Big.ZERO, Big.from(42.0)) - Big.from(42.0)) < 1e-12)
	falhas += _ok("pow", absf(Big.pow_n(Big.from(2.0), 1000.0) - 301.02999566398) < 1e-6)
	falhas += _ok("frac cheia", absf(Big.frac(Big.from(5.0), Big.from(10.0)) - 0.5) < 1e-9)
	falhas += _ok("frac clamp", Big.frac(Big.from(20.0), Big.from(10.0)) == 1.0)
	falhas += _ok("cmp", Big.gt(Big.from(1e100), Big.from(1e99)))
	# custos geométricos: base 10, growth 1.15, 60 níveis
	var soma := Big.geo_sum(10.0, 1.15, 0, 60)
	falhas += _ok("geo_sum", absf(Big.to_f(soma) - 292199.9) < 500.0)
	var n := Big.max_afford(Big.from(1000000.0), 10.0, 1.15, 0)
	falhas += _ok("max_afford=68", n == 68)
	falhas += _ok("max_afford 0", Big.max_afford(Big.from(1.0), 10.0, 1.15, 0) == 0)
	# precisão em números enormes
	var enorme := Big.from_log(500.0)
	falhas += _ok("precisao e500", absf(Big.sub(Big.add(enorme, Big.from_log(499.0)), Big.from_log(499.0)) - enorme) < 1e-9)
	falhas += _ok("save roundtrip", Big.from_save(Big.to_save(enorme)) == enorme)
	falhas += _ok("save zero", Big.is_zero(Big.from_save(Big.to_save(Big.ZERO))))
	print("===BIG-TEST=== falhas=%d" % falhas)
	quit(0 if falhas == 0 else 1)

func _ok(nome: String, cond: bool) -> int:
	if not cond:
		print("FALHOU: ", nome)
		return 1
	return 0
