#include <stdio.h>
#include <SDL2/SDL.h>

int main(int argc, char **argv) 
{
    SDL_Init(SDL_INIT_EVERYTHING);
    SDL_Window *window = SDL_CreateWindow("pongo", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 32*8, 32*8, 0);
    SDL_Renderer *renderer = SDL_CreateRenderer(window, -1, 0);


    return 0;
}
