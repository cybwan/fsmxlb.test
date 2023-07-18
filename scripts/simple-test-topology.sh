#!/bin/bash

docker=$1
HADD="sudo ip netns add "
LBHCMD="sudo ip netns exec fsmxlb "
HCMD="sudo ip netns exec "

id=`docker ps -f name=fsmxlb | cut  -d " "  -f 1 | grep -iv  "CONTAINER"`
echo $id
pid=`docker inspect -f '{{.State.Pid}}' $id`
echo $pid
if [ ! -f /var/run/netns/fsmxlb ]; then
  sudo touch /var/run/netns/fsmxlb
  sudo mount -o bind /proc/$pid/ns/net /var/run/netns/fsmxlb
fi

$HADD ep1
$HADD ep2
$HADD ep3
$HADD h1

## Configure load-balancer end-point ep1
sudo ip -n fsmxlb link add eflb1ep1 type veth peer name eep1flb1 netns ep1
sudo ip -n fsmxlb link set eflb1ep1 mtu 9000 up
sudo ip -n ep1 link set eep1flb1 mtu 7000 up
$LBHCMD ip addr add 31.31.31.254/24 dev eflb1ep1
$HCMD ep1 ifconfig eep1flb1 31.31.31.1/24 up
$HCMD ep1 ip route add default via 31.31.31.254
$HCMD ep1 ifconfig lo up
$HCMD ep1 pipy -e "pipy().listen(8080).serveHTTP(new Message('Hi, I am from ep1.\n'))" 1>/dev/null 2>&1 &

## Configure load-balancer end-point ep2
sudo ip -n fsmxlb link add eflb1ep2 type veth peer name eep2flb1 netns ep2
sudo ip -n fsmxlb link set eflb1ep2 mtu 9000 up
sudo ip -n ep2 link set eep2flb1 mtu 7000 up
$LBHCMD ip addr add 32.32.32.254/24 dev eflb1ep2
$HCMD ep2 ifconfig eep2flb1 32.32.32.1/24 up
$HCMD ep2 ip route add default via 32.32.32.254
$HCMD ep2 ifconfig lo up
$HCMD ep2 pipy -e "pipy().listen(8080).serveHTTP(new Message('Hi, I am from ep2.\n'))" 1>/dev/null 2>&1 &

## Configure load-balancer end-point ep3
sudo ip -n fsmxlb link add eflb1ep3 type veth peer name eep3flb1 netns ep3
sudo ip -n fsmxlb link set eflb1ep3 mtu 9000 up
sudo ip -n ep3 link set eep3flb1 mtu 7000 up
$LBHCMD ip addr add 33.33.33.254/24 dev eflb1ep3
$HCMD ep3 ifconfig eep3flb1 33.33.33.1/24 up
$HCMD ep3 ip route add default via 33.33.33.254
$HCMD ep3 ifconfig lo up
$HCMD ep3 pipy -e "pipy().listen(8080).serveHTTP(new Message('Hi, I am from ep3.\n'))" 1>/dev/null 2>&1 &

## Configure load-balancer end-point h1
sudo ip -n fsmxlb link add eflb1h1 type veth peer name eh1flb1 netns h1
sudo ip -n fsmxlb link set eflb1h1 mtu 9000 up
sudo ip -n h1 link set eh1flb1 mtu 7000 up
$LBHCMD ip addr add 10.10.10.254/24 dev eflb1h1
$HCMD h1 ifconfig eh1flb1 10.10.10.1/24 up
$HCMD h1 ip route add default via 10.10.10.254
$HCMD h1 ifconfig lo up

docker exec fsmxlb fsmxlbc create lb 20.20.20.1 --tcp=8080:8080 --endpoints=31.31.31.1:1,32.32.32.1:1,33.33.33.1:1
#docker exec fsmxlb fsmxlbc create lb 20.20.20.1 --tcp=8080:8080 --select=hash --mode=dsr --endpoints=31.31.31.1:1,32.32.32.1:1,33.33.33.1:1