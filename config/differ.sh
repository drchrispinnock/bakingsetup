
# dub
echo "===> dub"
for i in fra sin nrt; do
	diff production-dub production-$i
done
sleep 3

echo ""
echo "===> sin"
for i in fra dub nrt; do
	diff production-sin production-$i
done
sleep 3

echo ""
echo "===> dub vs IPv6"
for i in dub pdx; do
	diff production-dub production-$i-ipv6
done
sleep 3

echo ""
echo "===> dub vs alphanet/zeronet"
for i in alphanet zeronet; do
	diff production-dub $i
done
sleep 3

echo ""
echo "===> master vs all"
for i in production-fra production-sin production-nrt production-dub production-dub-ipv6 production-pdx-ipv6 alphanet zeronet; do
	diff master $i
done
