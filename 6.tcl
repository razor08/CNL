set ns [new Simulator]

set error_rate 0.00

$ns color 1 Blue
$ns color 2 Red

#Open trace and NAM trace file
set traceFile [open 6.tr w]
$ns trace-all $traceFile
set namFile [open 6.nam w]
$ns namtrace-all $namFile

#Finish Procedure
proc finish {} {
	global ns namFile traceFile
    $ns flush-trace
	#Close the trace files
    close $traceFile
    close $namFile
	exec awk -f 6.awk 6.tr & 
	exec nam 6.nam &
    exit 0
}


set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns simplex-link $n2 $n3 0.3Mb 100ms DropTail
$ns simplex-link $n3 $n2 0.3Mb 100ms DropTail

set lan [$ns newLan "$n3 $n4 $n5" 0.5Mb 40ms LL Queue/DropTail MAC/802_3 Channel]


$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns simplex-link-op $n2 $n3 orient right

$ns queue-limit $n2 $n3 20
$ns simplex-link-op $n2 $n3 queuePos 0.5

set loss_module [new ErrorModel]
$loss_module ranvar [new RandomVariable/Uniform]
$loss_module drop-target [new Agent/Null]
$loss_module set rate_ $error_rate
$ns lossmodel $loss_module $n2 $n3


set tcp [new Agent/TCP/Newreno]
$tcp set fid_ 1
$tcp set packetSize_ 552
$ns attach-agent $n0 $tcp
set sink0 [new Agent/TCPSink/DelAck]
$ns attach-agent $n4 $sink0
$ns connect $tcp $sink0

set ftp [new Application/FTP]
$ftp set type_ FTP
$ftp attach-agent $tcp


set udp0 [new Agent/UDP]
$udp0 set fid_ 2
$ns attach-agent $n1 $udp0
set null0 [new Agent/Null]
$ns attach-agent $n5 $null0
$ns connect $udp0 $null0

set cbr [new Application/Traffic/CBR]
$cbr set packetSize_ 1000
$cbr set rate_ 0.2Mb
$cbr set random_ false
$cbr attach-agent $udp0

$ns at 0.1 "$cbr start"
$ns at 1.0 "$ftp start"
$ns at 124.0 "$ftp stop"
$ns at 124.5 "$cbr stop"
$ns at 125.0 "finish"

#Run Simulation
$ns run
