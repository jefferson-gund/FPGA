%Desenvolvido por: Jefferson Gund.
%Exemplo de chamada da funcao:
%[outfname, rows, cols,bits] = img2VHDL('pou.bmp', 'pou.txt', 6, 7)

%A função abre uma imagem em formato BMP e transforma em código VHDL para
%criar blocos de memória para imagens, no formato:

%bits= numero de bits (niveis de representacao de cores) por tom R G e B. Por exemplo, se bits=3, R,G,B=3 bits.

%constant imagem : rom :=(
%	 (X"888",X"888",X"888",X"888",X"888",X"888"),
%    (X"888",X"888",X"888",X"888",X"888",X"888"),
%    (X"888",X"888",X"888",X"888",X"888",X"888"),
%    (X"888",X"888",X"888",X"888",X"888",X"888"),
%    (X"888",X"888",X"888",X"888",X"888",X"888"),
%    (X"888",X"888",X"888",X"888",X"888",X"888"),
%    (X"888",X"888",X"888",X"888",X"888",X"888")
%    );

function [nome_saida, linhas, colunas] = img2VHDL(arquivo_entrada, nome_saida, num_linhas, num_colunas)

bits=3
img = imread(arquivo_entrada);
imgresized = imresize(img, [num_linhas num_colunas]);

[linhas, colunas, rgb] = size(imgresized);

imgscaled = imgresized/16 - 1;
imshow(imgscaled*16);

fid = fopen(nome_saida,'w');
fprintf(fid,'--Linha x Colunas: %3u x %3u\n',linhas,colunas);
%fprintf(fid,'-- %Bits por pixel: %3u\n',bits);
fprintf(fid,'--Numero de pixels: = %4u;\n',linhas*colunas);
fprintf(fid,'--Definicao do simbolo: \n\n');

fprintf(fid,'----------------------------------------------------------------------------------------------------------------- \n\n');



count = 0;
fprintf(fid,'	constant imagem : rom :=(\n');
for r = 1:linhas
    fprintf(fid,'			(');
    for c = 1:colunas
        red = uint8(imgscaled(r,c,1));% uint8 = 256    256/2 = 128
        
        
        if(red >= 8)% necessario converter para valor binario para se adequar `a saida de 3 bits da placa da China.
            red=1;
        else
            red=0;
        end
        
        green = uint8(imgscaled(r,c,2));
        if(green >= 6)
            green=1;
        else
            green=0;
        end
        
        blue = uint8(imgscaled(r,c,3));
        if(blue >= 3)
            blue=1;
        else
            blue=0;
        end
        
        color(1)= red;
        color(2)= green;
        color(3)= blue;
        
        %fprintf(fid,'X"%d%d%d"',color(1),color(2),color(3));%Escreve o valor no formato hexadecimal. 
        fprintf(fid,'"%d%d%d"',color(1),color(2),color(3));%Escreve o valor em binario.
        if(c ~= colunas)
              fprintf(fid,',');%Separa os valores RGB nas colunas da matriz. 
        end
        count = count + 1;
    end
    if(r ~= linhas)
        fprintf(fid,'),\n');
    else
        fprintf(fid,')\n');
    end

end
fprintf(fid,'	);\n\n');
fclose(fid);
