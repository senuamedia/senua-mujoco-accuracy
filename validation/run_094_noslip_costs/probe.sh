#!/usr/bin/env bash
# Run 094: a design probe, not registered: it finds where to look and decides nothing. Issue 14 (M3), two of noslip's
# costs, on Google DeepMind's Linux release of MuJoCo 3.16.0.
# Part A, a joint equality with joint friction (MuJoCo's issue #2430, whose cause its maintainer placed in noslip): two
# bodies of 1 kg, A on a slide joint falling under gravity, B on a horizontal slide joint with joint friction
# (frictionloss) F, coupled by a joint equality that says B moves as A does. Nothing touches. With the equality kept,
# both move the same, A's weight against B's friction. Played 1 s at 2 ms with noslip off, 5 and 100 iterations, for F
# of 0.5, 2, 5, 9 and 20 N. Read by Senua AI's corrected measure: `gap` between A's motion and B's (the largest
# difference, the equality's violation), and `final` on each.
# Part B, inverse dynamics: MuJoCo's own forward-inverse comparison (its fwdinv flag, mj_compareFwdInv each step) on the
# cube Study 19 held (1.561 kg, half-size 0.0489 m, friction 0.438), held from turning, pushed at 0.5 and 0.95 of its
# limit, and slid at 1 m/s, at 1.71 ms: under MuJoCo's defaults, under the elliptic cone, and under Senua AI's
# configuration (the elliptic cone, 100 noslip iterations). Read: the largest of each comparison over the play (the
# contact rig's new setting fwdinv=1; the rig as it was before it and the rig now, fwdinv unset, compared byte for byte).
# usage: probe.sh <sx_contact, the corrected measure> <work folder>   (repository root, on the cloud machine; the work
#        folder holds the release in mujoco-3.16.0)
set -u
B="$(cd "$(dirname "${1:?usage: see the header}")" && pwd)/$(basename "$1")"; W="$(cd "${2:?}" && pwd)"; R="$(pwd)"
O="$R/validation/run_094_noslip_costs"; mkdir -p "$O/scenes" "$O/p"; date -u +%FT%TZ > "$O/played_at.txt"
X=$(mktemp -d); cp -R "$R/tools" "$X/"; cp "$O/mjc_contact_before.c" "$X/tools/mjc_contact_before.c"
( cd "$X" && for r in mjc_scene mjc_contact mjc_contact_before; do MUJOCO_DIR="$W/mujoco-3.16.0" tools/build_rig.sh $r > /dev/null; done )
# the rig before fwdinv= and the rig now, fwdinv unset: a hold and a slide, byte for byte
CUBE="mass=1.561 radius=0.0489 mu=0.438"
"$X/tools/mjc_contact_before" "$X/id_b1.txt" dt=0.00171 h0=0 $CUBE push=4 pushat=0.4 secs=1.6 cone=elliptic noslip=100 > "$X/id_b1.stats"
"$X/tools/mjc_contact" "$X/id_n1.txt" dt=0.00171 h0=0 $CUBE push=4 pushat=0.4 secs=1.6 cone=elliptic noslip=100 > "$X/id_n1.stats"
"$X/tools/mjc_contact_before" "$X/id_b2.txt" dt=0.00171 h0=0 vx0=1 $CUBE secs=1 > "$X/id_b2.stats"
"$X/tools/mjc_contact" "$X/id_n2.txt" dt=0.00171 h0=0 vx0=1 $CUBE secs=1 > "$X/id_n2.stats"
{ for k in 1 2; do
    cmp -s "$X/id_b$k.txt" "$X/id_n$k.txt" && echo "identity play $k: the same bytes" || echo "identity play $k: DIFFERENT"
    cmp -s "$X/id_b$k.stats" "$X/id_n$k.stats" && echo "identity statistics $k: the same bytes" || echo "identity statistics $k: DIFFERENT"
  done; } > "$O/identity.txt"
# ---- part A
for F in 0.5 2 5 9 20; do
  cat > "$O/scenes/coupled_F$F.xml" <<EOF
<mujoco model="coupled"><option timestep="0.002" gravity="0 0 -9.8"/>
<worldbody>
<body name="a" pos="0 0 1"><joint name="A" type="slide" axis="0 0 -1"/><geom type="box" size="0.05 0.05 0.05" mass="1" contype="0" conaffinity="0"/></body>
<body name="b" pos="0.5 0 1"><joint name="B" type="slide" axis="1 0 0" frictionloss="$F"/><geom type="box" size="0.05 0.05 0.05" mass="1" contype="0" conaffinity="0"/></body>
</worldbody>
<equality><joint joint1="B" joint2="A" polycoef="0 1 0 0 0"/></equality>
</mujoco>
EOF
done
: > "$O/p/stats.txt"
{
  echo "with the equality kept, A and B move the same: (9.8 - F) / 2 m/s2 while F is under 9.8 N, and not at all at 20 N"
  for F in 0.5 2 5 9 20; do
    for ns in off:"" n5:"noslip=5" n100:"noslip=100"; do
      nn=${ns%%:*}; no=${ns#*:}
      for bd in a:0,0,-1 b:1,0,0; do
        bn=${bd%%:*}; ax=${bd#*:}
        # shellcheck disable=SC2086
        "$X/tools/mjc_scene" "$O/p/coupled_F${F}_${nn}_$bn.txt" scene="$O/scenes/coupled_F$F.xml" body=$bn axis=$ax secs=1 $no | sed "s|^STATS|STATS run coupled_F${F}_${nn}_$bn|" >> "$O/p/stats.txt"
      done
      fa=$("$B" final "$O/p/coupled_F${F}_${nn}_a.txt" | tail -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "angle_urad") print $(i + 1) }')
      fb=$("$B" final "$O/p/coupled_F${F}_${nn}_b.txt" | tail -1 | awk '{ for (i = 1; i < NF; i++) if ($i == "angle_urad") print $(i + 1) }')
      echo "F $F N noslip $nn | A moved $fa nm, B moved $fb nm | $("$B" gap 2000000 "$O/p/coupled_F${F}_${nn}_a.txt" "$O/p/coupled_F${F}_${nn}_b.txt" | tail -1)"
    done
  done
} > "$O/reading_equality.txt"
# ---- part B
LIM=$(awk 'BEGIN { printf "%.6f", 0.438 * 1.561 * 9.8 }')
{
  for cfg in defaults:"" elliptic:"cone=elliptic" config:"cone=elliptic noslip=100"; do
    cn=${cfg%%:*}; co=${cfg#*:}
    for play in hold50:0.5 hold95:0.95 slide:0; do
      pn=${play%%:*}; fr=${play#*:}
      f="$O/p/fwdinv_${cn}_$pn.txt"
      if [ "$pn" = slide ]; then
        # shellcheck disable=SC2086
        st=$("$X/tools/mjc_contact" "$f" dt=0.00171 h0=0 vx0=1 $CUBE secs=1 fwdinv=1 $co)
      else
        pu=$(awk -v f="$fr" -v l="$LIM" 'BEGIN { printf "%.6f", f * l }')
        # shellcheck disable=SC2086
        st=$("$X/tools/mjc_contact" "$f" dt=0.00171 h0=0 $CUBE push=$pu pushat=0.4 secs=1.6 fwdinv=1 $co)
      fi
      echo "$st" | sed "s|^STATS|STATS run fwdinv_${cn}_$pn|" >> "$O/p/stats.txt"
      echo "$cn $pn | $(echo "$st" | grep -o 'most_fwdinv_constraint [0-9.e+-]* most_fwdinv_applied [0-9.e+-]*') | $("$B" creep "$f" | tail -1 | grep -o 'mean_speed_ums [-0-9]*')"
    done
  done
} > "$O/reading_fwdinv.txt"
rm -rf "${X:?}"
date -u +%FT%TZ > "$O/finished.txt"
