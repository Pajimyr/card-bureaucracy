"""Simulátor balance pro Card Bureaucracy. Zrcadlí pravidla z scripts/main.gd
a kariéru (patra, groše, obchod) ze scripts/game_state.gd.
Hráč je heuristika (nasazuje karty s nejvyšším ÚT+ŽIV), takže výhry jsou spíš spodní odhad.
Spuštění: python3 tools/balance_sim.py          (jednotlivé případy + celá kariéra)
          python3 tools/balance_sim.py career   (jen celá kariéra)
"""
import random, sys

PLAYER_POOL = [(2,3),(3,2),(1,5),(4,2),(1,2),(1,4),(5,4),(2,4),(2,3),(3,3)]
ENEMY_POOL  = [(2,4),(3,3),(4,4),(1,3),(3,5)]
LANES = 3

# Ruleta (main.gd / roulette.gd): 8 segmentů. ("cards", n) = n nových karet,
# "rib" = zlomené žebro (-4 max HP), "hand" = přijdeš o ruku (-1 karta/tah).
ROULETTE = [("cards",2),("rib",0),("cards",3),("hand",0),("rib",0),("cards",2),("rib",0),("rib",0)]
RIB_HP = 4
MAX_RIBS = 3

def spin(st, alive, hand, rnd):
    kind, n = rnd.choice(ROULETTE)
    if kind == "hand" and st["cpt"] <= 1:
        kind = "rib"
    if kind == "cards":
        new = mk(PLAYER_POOL, n, rnd)
        alive.extend(new); hand.extend(new)
    elif kind == "hand":
        st["cpt"] -= 1
    else:
        if st["ribs"] < MAX_RIBS:
            st["ribs"] += 1
            st["maxhp"] -= RIB_HP
            st["player"] = max(1, min(st["player"], st["maxhp"]))
        else:
            st["player"] = max(1, st["player"] - RIB_HP)
    st["spins"] += 1

def mk(pool, n, rnd):
    return [{"atk":a,"hp":h,"max":h} for a,h in (rnd.choice(pool) for _ in range(n))]

def place(board, deck_alive, hand, k, is_player, rnd):
    """Placement heuristic: front first, back only behind a front; pick highest atk+hp."""
    placed = 0
    while placed < k:
        cands = []
        for idx in range(6):
            if board[idx] is not None: continue
            if idx >= LANES and board[idx-LANES] is None: continue
            cands.append(idx)
        if not cands: break
        pool = hand if is_player else [c for c in deck_alive if all(c is not b for b in board if b)]
        if not pool: break
        # heuristic: best card by atk+hp, front slots preferred
        best = max(pool, key=lambda c: c["atk"]+c["hp"]) if is_player else rnd.choice(pool)
        idx = min(cands, key=lambda i: (i >= LANES, i % LANES))
        board[idx] = best
        if is_player: hand.remove(best)
        placed += 1

def combat(P, E, st):
    """Mirror of _resolve_combat / _attack_pass / _cleanup_dead."""
    attackers = []
    for lane in range(LANES):
        if P[lane] is not None: attackers.append((True, lane))
        if E[lane] is not None: attackers.append((False, lane))
    passes = 0
    while attackers and passes < 20:
        passes += 1
        for is_p, lane in attackers:
            board_a = P if is_p else E
            att = board_a[lane]
            if att is None: continue
            board_d = E if is_p else P
            tgt = board_d[lane]
            if tgt is not None:
                hp_before = max(tgt["hp"], 0)
                tgt["hp"] -= att["atk"]
                over = att["atk"] - hp_before
                if over > 0:
                    back = board_d[lane+LANES]
                    if back is not None:
                        back["hp"] -= over
                    elif is_p:
                        st["official"] -= over
                    else:
                        st["player"] -= over
            elif is_p:
                st["official"] -= att["atk"]
            else:
                st["player"] -= att["atk"]
        # cleanup
        attackers = []
        for is_p in (True, False):
            b = P if is_p else E
            for i in range(6):
                if b[i] is not None and b[i]["hp"] <= 0:
                    b[i] = None
                    if is_p: st["lost"] += 1
            for lane in range(LANES):
                if b[lane] is None and b[lane+LANES] is not None:
                    b[lane] = b[lane+LANES]; b[lane+LANES] = None
                    attackers.append((is_p, lane))

def game(cfg, rnd):
    deck = mk(PLAYER_POOL, cfg["pdeck"], rnd) + mk([(4, 4)], cfg.get("stamps", 0), rnd)
    edeck = mk(cfg.get("epool", ENEMY_POOL), cfg["edeck"], rnd)
    P = [None]*6; E = [None]*6
    hand = []
    st = {"player": cfg["php"], "official": cfg["ohp"], "lost": 0,
          "cpt": cfg["cpt"], "ribs": 0, "maxhp": cfg["php"], "spins": 0}
    alive = list(deck)
    def refill():
        while len(hand) < cfg["hand"]:
            av = [c for c in alive if c not in hand and c not in P]
            if not av: break
            hand.append(rnd.choice(av))
    refill()
    turn = 0
    while turn < cfg["maxturns"]:
        turn += 1
        if not hand and cfg.get("roulette", True):
            spin(st, alive, hand, rnd)
        place(P, alive, hand, st["cpt"], True, rnd)
        # enemy
        ealive = [c for c in edeck if c not in E]
        ecount = 0
        for idx in range(6):
            if ecount >= cfg["ecpt"]: break
            if E[idx] is not None: continue
            if idx >= LANES and E[idx-LANES] is None: continue
            av = [c for c in edeck if all(c is not b for b in E if b)]
            if not av: break
            E[idx] = rnd.choice(av); ecount += 1
        combat(P, E, st)
        # deaths of player cards remove from deck
        alive = [c for c in alive if c["hp"] > 0]
        for c in list(hand):
            if c["hp"] <= 0: hand.remove(c)
        if st["official"] <= 0: return "win", turn, st
        if st["player"] <= 0: return "lose_hp", turn, st
        if not alive and not cfg.get("roulette", True): return "lose_deck", turn, st
        refill()
    return "timeout", turn, st

def run(cfg, n=20000, seed=1):
    rnd = random.Random(seed)
    from collections import Counter
    res = Counter(); turns=[]
    global LAST_ST
    for _ in range(n):
        r, t, _ = game(cfg, rnd)
        res[r] += 1
        if r == "win": turns.append(t)
    wr = res["win"]/n
    avg = sum(turns)/len(turns) if turns else 0
    return wr, avg, dict(res)

# --- Kariéra (GameState.RANKS, DIFFICULTIES, ITEMS) -----------------------------
E = {"Referent": (2,4), "Revizor": (3,3), "Vedoucí odboru": (4,4), "Úředník podatelny": (1,3),
     "Kontrolor": (3,5), "Tajemník": (3,6), "Ředitel": (5,6)}
RANKS = [
    {"hp": 16, "deck": 8,  "pool": ["Úředník podatelny", "Referent", "Revizor"]},
    {"hp": 20, "deck": 9,  "pool": ["Referent", "Revizor", "Vedoucí odboru", "Úředník podatelny", "Kontrolor"]},
    {"hp": 20, "deck": 8,  "pool": ["Referent", "Revizor", "Vedoucí odboru", "Kontrolor"]},
    {"hp": 24, "deck": 6,  "pool": ["Referent", "Revizor", "Vedoucí odboru", "Kontrolor", "Tajemník", "Ředitel"]},
]
DIFFS = [
    {"name": "Úřední hodiny", "pdeck": 10, "round": 8,  "hand": 25, "prost": 30, "mult": 0.8},
    {"name": "Pondělí ráno",  "pdeck": 9,  "round": 10, "hand": 20, "prost": 40, "mult": 1.0},
    {"name": "Pátek 14:55",   "pdeck": 8,  "round": 15, "hand": 15, "prost": 55, "mult": 1.3},
]
ITEM = {"salve": 20, "vest": 25, "fake_stamp": 22, "bribe": 12, "coffee": 15}
START, REWARD, BRIBE_HP, VEST_HP = 50, 20, 6, 4

def career(d, rnd, shop=True, max_cases=40):
    """Celá hra po tutorialu. Vrací ("win"|"stuck"|"timeout", počet případů)."""
    g = START + REWARD  # tutorial nejde prohrát a dává +20
    price = lambda k: round(ITEM[k] * d["mult"])
    rank, hands, prost, ribs, vests, stamps = 0, 0, 0, 0, 0, 0
    for case in range(1, max_cases + 1):
        if case > 1 or True:  # každý případ po tutorialu se platí
            if g < d["round"]:
                if hands + prost < 2:            # prodej ruky
                    hands += 1; g += d["hand"]
                    if g < d["round"]: return "stuck", case
                else:
                    return "stuck", case
            g -= d["round"]
        bribe = coffee = 0
        if shop:  # nákup: drží rezervu na další kolo, pak razítka, vesty, mast, před bossem úplatek+kafe
            reserve = d["round"]
            def buy(k):
                nonlocal g
                if g - price(k) >= reserve: g -= price(k); return True
                return False
            if rank == 3:
                if buy("bribe"): bribe = 1
                if buy("coffee"): coffee = 1
            if ribs and buy("salve"): ribs -= 1
            while stamps < 3 and buy("fake_stamp"): stamps += 1
            if vests < 2 and buy("vest"): vests += 1
        r = RANKS[rank]
        maxhp = 20 - 4 * ribs + VEST_HP * vests
        cfg = dict(pdeck=d["pdeck"], edeck=r["deck"], php=maxhp, ohp=max(1, r["hp"] - BRIBE_HP * bribe),
                   hand=5, cpt=max(1, 3 - hands) + coffee, ecpt=2, maxturns=80, stamps=stamps,
                   epool=[E[n] for n in r["pool"]])
        res, _, st = game(cfg, rnd)
        hands += cfg["cpt"] - st["cpt"]  # ruleta "ruka" snižuje cpt o 1
        ribs = min(3, ribs + st["ribs"])
        if res == "win":
            g += REWARD; rank += 1
            if rank == len(RANKS): return "win", case
    return "timeout", max_cases

def run_career(n=5000, seed=7):
    rnd = random.Random(seed)
    for shop in (False, True):
        print("Celá kariéra" + (" s nákupy v baru" if shop else " bez nákupů"))
        for d in DIFFS:
            from collections import Counter
            res = Counter(); cases = []
            for _ in range(n):
                r, c = career(d, rnd, shop)
                res[r] += 1
                if r == "win": cases.append(c)
            avg = sum(cases) / len(cases) if cases else 0
            print(f"  {d['name']:14s} výhra {res['win']/n*100:5.1f} %  průměr případů do výhry {avg:.1f}  {dict(res)}")

def run_ranks(n=10000, seed=3):
    print("Jednotlivá patra (krysa bez efektů, Pondělí ráno, balíček 9)")
    for i, r in enumerate(RANKS):
        cfg = dict(pdeck=9, edeck=r["deck"], php=20, ohp=r["hp"], hand=5, cpt=3, ecpt=2, maxturns=80,
                   epool=[E[x] for x in r["pool"]])
        wr, avg, res = run(cfg, n=n, seed=seed)
        print(f"  patro {i+1}: výhra {wr*100:5.1f} %  průměr kol {avg:.1f}")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "career":
        run_career()
        sys.exit(0)
    run_ranks()
    run_career()
