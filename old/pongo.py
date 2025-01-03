import sys
import random
import pygame


# Ugly state
regs = {"Ac": 0, "Lp": 0, "Dx": 0, "Dy": 0, "Co": 0}
pc = 20

ram = [0] * 256

pygame.init()
screen = pygame.display.set_mode((32*32, 32*32))
fb = pygame.Surface((32, 32)).convert(8)
sfb = pygame.Surface((32*32, 32*32)).convert(8)

fb.fill(pygame.Color(0, 255, 255))

fb.set_palette_at(0, (0, 0, 0))
fb.set_palette_at(160, (215, 0, 0))
fb.set_palette_at(34, (0, 175, 0))
fb.set_palette_at(240, (88, 88, 88))
fb.set_palette_at(255, (238, 238, 238))

sfb.set_palette(fb.get_palette())


def assemble(filename):
    rawasm = open(filename, "r")
    asm = rawasm.readlines()
    rawasm.close()

    cpc = 0
    labels = {}
    defines = {}
    hits = 0

    for statement in asm:
        statement = statement.strip()
        tok = statement.split()

        if len(tok) > 0 and not tok[0].startswith("#"):
            adv = True
            match tok[0]:
                case "@Pc":
                    cpc = int(tok[1])
                    adv = False
                case "Nop":
                    ram[cpc] = 0x00
                case "IncAc":
                    ram[cpc] = 0x10
                case "IncDx":
                    ram[cpc] = 0x20   
                case "IncDy":
                    ram[cpc] = 0x30           
                case "Jlp":
                    ram[cpc] = 0x40               
                    ram[cpc] |= int(tok[1]) & 0x0f
                case "LdAc":
                    ram[cpc] = 0x50              
                    imd = (labels[tok[1]] if tok[1] in labels else tok[1])
                    ram[cpc] |= int(imd) & 0x0f
                case "LdDx":
                    ram[cpc] = 0x60
                    imd = (labels[tok[1]] if tok[1] in labels else tok[1])
                    ram[cpc] |= int(imd) & 0x0f
                case "LdDy":
                    ram[cpc] = 0x70              
                    imd = (labels[tok[1]] if tok[1] in labels else tok[1])
                    ram[cpc] |= int(imd) & 0x0f
                case "LdLp":
                    ram[cpc] = 0x80               
                    ram[cpc] |= int(tok[1]) & 0x0f
                case "LdCo":
                    ram[cpc] = 0x90             
                case "Pulse":
                    ram[cpc] = 0xa0
                    ram[cpc] |= int(tok[1]) & 0x0f
                case "StCo":
                    ram[cpc] = 0xb0              
                case "Jmp":
                    ram[cpc] = 0xc0
                    ram[cpc] |= int(tok[1]) & 0x0f
                case "@Data":
                    ram[cpc] = int(tok[1]) & 0xff   
                case "@Write":
                    ram[cpc] = 0xa4
                case "@Clear":
                    ram[cpc] = 0xa8
                case "@Lbl":
                    adv = False
                    labels[tok[1]] = cpc
                case "@Def":
                    adv = False
                    defines[tok[1]] = tok[2]

            if adv:
                hits += 1
                cpc += 1

            cpc &= 0xff
    
    print("Memory usage is " + str(hits) + "/256b")
    

def step_cpu():
    global pc
    global regs
    global ram

    # Load up instruction 
    current_inst = ram[pc]
    opcode = current_inst >> 4
    imdjmp = (current_inst & 0xf) | (0xf0 if current_inst & 0x8 else 0x00)
    immed = (current_inst & 0xf)

    print(" R " + str(opcode) + " dat " + str(immed))

    match opcode:
        case 0:
            # No op
            pc = pc
        case 1: 
            # Inc Ac
            regs["Ac"] += 1
        case 2:
            # Inc Dx
            regs["Dx"] += 1
        case 3:
            # Inc Dy
            regs["Dy"] += 1
        case 4:
            # Jlp
            if regs["Lp"] != 0:
                regs["Lp"] -= 1
                pc += imdjmp
        case 5:
            # Ld A
            regs["Ac"] = ram[immed]
        case 6:
            # Ld Dx
            regs["Dx"] = ram[immed]
        case 7: 
            # Ld Dy
            regs["Dy"] = ram[immed]
        case 8: 
            # Ld Lp
            regs["Lp"] = immed
        case 9:
            # Ld Co
            regs["Co"] = ram[regs["Ac"]]
        case 10:
            # Pulse
            if immed & 0x8 > 0:
                # Clear
                fb.fill(pygame.Color(black))
            if immed & 0x4 > 0:
                # Write pixel
                fb.set_at((regs["Dx"], regs["Dy"]), regs["Co"])
        case 11:
            # St Co
            ram[regs["Ac"]] = regs["Co"]
        case 12:
            # Jmp
            pc += immed
        case _:
            # No op
            pc = pc

    # Disgusting
    if opcode != 12:
        pc += 1

    regs["Ac"] &= 0xff
    regs["Dx"] &= 0xff
    regs["Dy"] &= 0xff
    regs["Lp"] &= 0xff
    regs["Co"] &= 0xff
    pc &= 0xff
  


if __name__ == "__main__":

    assemble(sys.argv[1])

    run = True
    do_tick = True

    while run:
        # Manage shit
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                run = False
            #elif event.type == pygame.KEYDOWN:
            #    do_tick = True

        if do_tick:
            #do_tick = False
            
            # Print state
            print("PC " + str(pc))
            print(regs)

            # Execute
            step_cpu()
            
            # Show it off
            pygame.transform.scale(fb, (32*32, 32*32), dest_surface=sfb)
            screen.blit(sfb, (0, 0))
            pygame.display.update()
            pygame.time.wait(25)


    pygame.quit()
