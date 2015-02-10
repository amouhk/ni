PROJET SLE 3A ENSIMAG
Binome:  AMOUH & PASCAL
---------------------------------
Utilisation:
	Pour utiliser les sources du projet l'outils de design matériel
	vivado xilinx est indispensable.
	
	Pour pourvoir réalisé les testbench, il faut avant tout rajouté une fifo de capacité 16x32bits dans 
	le projet cree.
	Etape:
		1-creer un projet vivado 
		2-importé tous les source src/vhd/* et src/bench
		3-Dans la fenetre "Flow Navigator" de vivado clicquez sur "IP Catalog" dans l'onglet Project Manager.
		4-Dans la fenetre qui s'affiche (IP Catalog) recherchez fifo (FIFO Generator) puis double-clicquez
		5_La fenetre de FIFO Generator s'ouvre
			change le nom du composont
				Component Name = fifo
			Ne rien changez dans l'onglet "basic"
			Dans l'onglet "native ports"
				write width = 32
				write Depth = 16
				
				Reset Type = Synchonous Reset
				
				->valider
				->Generate
		
		6 Les bench peuvent etre utilises.