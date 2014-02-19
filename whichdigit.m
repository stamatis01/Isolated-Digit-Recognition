
function [ word ] = whichdigit( nll_IDX )
%helping function used for providing the right string for the indentified
%isolated digit
switch nll_IDX
    case 1, word = 'one';
    case 2, word = 'two';
    case 3, word = 'three';
    case 4, word = 'four';
    case 5, word = 'five';
    case 6, word = 'six';
    case 7, word = 'seven';
    case 8, word = 'eight';
    case 9, word = 'nine';
    case 10, word = 'zero';        
end
end

