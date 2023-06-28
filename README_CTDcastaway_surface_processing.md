%% BITACORA - SPV CTDcastAway surface data
	Nina Hoareau, 28/06/2023
	------------------------
Expliaction des differentes étapes à appliquer pour transformer les données brutes (RAW) des transectes de mesures  de Temperature et Salinité en set de données collocalisées avec la position du Pati de Vela/Paddle.

I) Générer un seul fichier de données de surface de TS à partir des différents fichiers de données de surface de TS
	1- A partir du terminal "bash" se placer dans le dossier des données RAW qui corresponde à la campagne
	2- Créer un fichier (tram_list.txt) qui contient la liste des fichiers à concatener: 		>> ls *CruiseDate* > tram_list.txt
	3- Ouvrir Matlab & aller dans le dossier /home/nina/Escritorio/WORK/Github/Paticientific/ -> ouvrir le code 'concat_CTDtram_file.m' -> modifier la variable 'cdate=CruiseDate' -> Run
	4- Copier tram_list.txt & file***_all.csv -> /home/nina/Escritorio/WORK/PatiCientific/data/SPV/SeaWater/Surface/CastAwayCTD/RAW/aggregate_surface_sections/
	5- Renomer le nom du fichier tram_list.txt à 10J101601_*date*_all_tram.csv
	
II) 
