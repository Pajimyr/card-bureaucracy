"""Simulátor balance pro Card Bureaucracy. Zrcadlí pravidla z scripts/main.gd.
Hráč je heuristika (nasazuje karty s nejvyšším ÚT+ŽIV), takže výhry jsou spíš spodní odhad.
Spuštění: python3 tools/balance_sim.py
"""
import random, sys

PLAYER_POOL = [(2,3),(3,2),(1,5),(4,2),(1,2),(1,4),(5,4),(2,4),(2,3),(3,3)]
ENEMY_POOL  = [(2,4),(3,3),(4,4),(1,3),(3,5)]
LANES = 3

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
    deck = mk(PLAYER_POOL, cfg["pdeck"], rnd)
    edeck = mk(ENEMY_POOL, cfg["edeck"], rnd)
    P = [None]*6; E = [None]*6
    hand = []
    st = {"player": cfg["php"], "official": cfg["ohp"], "lost": 0}
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
        place(P, alive, hand, min(cfg["cpt"], cfg["cpt_cap"](st) if "cpt_cap" in cfg else cfg["cpt"]), True, rnd)
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
        if st["official"] <= 0: return "win", turn
        if st["player"] <= 0: return "lose_hp", turn
        if not alive: return "lose_deck", turn
        refill()
    return "timeout", turn

def run(cfg, n=20000, seed=1):
    rnd = random.Random(seed)
    from collections import Counter
    res = Counter(); turns=[]
    for _ in range(n):
        r, t = game(cfg, rnd)
        res[r] += 1
        if r == "win": turns.append(t)
    wr = res["win"]/n
    avg = sum(turns)/len(turns) if turns else 0
    return wr, avg, dict(res)

if __name__ == "__main__":
    base = dict(pdeck=10, edeck=9, php=20, ohp=20, hand=5, cpt=3, ecpt=3, maxturns=80)
    tiers = {
        "současný stav": {},
        "Úřední hodiny (pdeck 12, ecpt 2)": {"pdeck": 12, "ecpt": 2},
        "Pondělí ráno (pdeck 11, ecpt 2)": {"pdeck": 11, "ecpt": 2},
        "Pátek 14:55 (pdeck 10, ecpt 2)": {"pdeck": 10, "ecpt": 2},
    }
    for name, ch in tiers.items():
        cfg = dict(base); cfg.update(ch)
        wr, avg, res = run(cfg, n=10000)
        print(f"{name:36s} výhra {wr*100:5.1f} %  průměr kol {avg:.1f}  {res}")
