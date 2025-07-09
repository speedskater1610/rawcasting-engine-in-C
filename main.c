//only for windows


#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <windows.h>
#include <conio.h>
#include <time.h>

char map[] =
    "11111111111111111111111111111111"
    "10000000000000000000000000000001"
    "10111111111111111100000000000001"
    "10000000000000000100000000000001"
    "10111100011110000100000000000001"
    "10000100010010000100000000000001"
    "10000100010010000111111111100001"
    "10000100010010000000000000100001"
    "10000111110011111111111110100001"
    "10000000000000000000000000100001"
    "10000000000000000000000000100001"
    "10001111111111111111111110100001"
    "10001000000000000000000000100001"
    "10001000000000000000000000100001"
    "10001000000000000000000000100001"
    "11111111111111111111111111111111";


#define MAP_WIDTH     32
#define MAP_HEIGHT    16
#define FOV           3.14159f / 4.0f
#define DEPTH         16.0f
#define SCREEN_WIDTH  120
#define SCREEN_HEIGHT 40

// so bool works
#define bool int
#define true 1
#define false 0

// one to ten one being easyiest 10 being hardest
int hardness = 5;
//diffreewnt keys for movement
char forwardKey = 'w';
char leftKey = 'a';
char backKey = 's';
char rightKey = 'd';
char fireKey = ' ';
char menuKey = 'm';


// struct for enemy data
struct Enemy {
    float xCords;
    float yCords;

    int health;
};
// helper function
struct Enemy spawnEnemy() {
    struct Enemy e;
    e.xCords = rand() % 32;
    e.yCords = rand() % 16;
    e.health = 10;
    return e;
};

//for the player to fire there weapon
void fireWeapon () {

}

void halfwaybullets () {
    for (int i = (SCREEN_WIDTH/2)-10; i >= 0; i--) {
        printf(" ");
    }
}

void openMenu () {
    system("cls");

    bool setting = true;


done :
    while (setting) {
        system("cls");
        //print the top boarder
        for (int i = SCREEN_WIDTH; i >= 0; i--) {
            printf("=");
        }

        //advance the cousor along half way and print settings
        for (int i = (SCREEN_WIDTH/2); i >= 0; i--) {
            printf(" ");
        }
        printf("SETTING\n\n");

        //go about halfway then print bullented list of every thing they can do 
        int whichBullet; 

        halfwaybullets();
        printf("- 1) change input type\n");
        halfwaybullets();
        printf("- 2) change hardness\n");
        halfwaybullets();
        printf("- 3) leave setting\n");
        halfwaybullets();

        scanf("%i", &whichBullet);

        if (whichBullet == 1) {
            goto change_input;
        } 
        else if (whichBullet == 2) {
            goto change_hardness;
        } 
        else if (whichBullet == 3) {
            goto end;
        }
    }

change_input:
    system("cls");
    //print the top boarder
    for (int i = SCREEN_WIDTH; i >= 0; i--) {
        printf("=");
    }

    //advance the cousor along half way and print heading
    for (int i = (SCREEN_WIDTH/2); i >= 0; i--) {
        printf(" ");
    }

    int whichKeyToChange;
    char holdingChar;

    //get what the Users wants to change 
    printf("Change Input Type\n\n");
    halfwaybullets();
    printf("1) forward - %c\n", forwardKey);
    halfwaybullets();
    printf("2) backwards - %c\n", backKey);
    halfwaybullets();
    printf("3) left - %c\n", leftKey);
    halfwaybullets();
    printf("4) right - %c\n", rightKey);
    halfwaybullets();
    printf("5) menu - %c\n", menuKey);
    halfwaybullets();
    printf("0) leave\n\n\n");

    halfwaybullets();
    printf("\t - ");
    scanf("%i", &whichKeyToChange);

    //what they want to change it to
    if (whichKeyToChange != 0) {
        printf("\n\nWhat do you want to change it to? - ");
        scanf(" %c", &holdingChar);
    }

    //assign the key
    switch (whichKeyToChange) {
        case 0:
            break;

        case 1:
            forwardKey = holdingChar;
            break;
        case 2:
            backKey = holdingChar;
            break;
        case 3:
            leftKey= holdingChar;
            break;
        case 4:
            rightKey = holdingChar;
            break;
        case 5:
            menuKey = holdingChar;
            break;
            
    }

    goto done; 


change_hardness :
    system("cls");
    //print the top boarder
    for (int i = SCREEN_WIDTH; i >= 0; i--) {
        printf("=");
    }

    //advance the cousor along half way and print heading
    for (int i = (SCREEN_WIDTH/2); i >= 0; i--) {
        printf(" ");
    }


    int changeHardnessTo;

    //get what the Users wants to change the hardness level to
    printf("Change Hardness\n\n");

    halfwaybullets();
    printf("\tchange hardness to [easy (1-10) hard] - ");
    scanf("%i", &changeHardnessTo);

    //assign it
    hardness = changeHardnessTo;

    goto done;
   
end:
    system("cls");
    return;
}

float playerX = 2.0f, playerY = 2.0f;
float playerA = 0.0f;

int main() {

    char startLetter = 
    printf("are you ready to start? Y/n - ");
    scanf(" %c", &startLetter);


    //make the screen buffer
    wchar_t *screen = malloc(sizeof(wchar_t) * SCREEN_WIDTH * SCREEN_HEIGHT);
    for (int i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT; i++)
        screen[i] = L' ';

    HANDLE hConsole = GetStdHandle(STD_OUTPUT_HANDLE);
    COORD bufferSize = { SCREEN_WIDTH, SCREEN_HEIGHT };
    SetConsoleScreenBufferSize(hConsole, bufferSize);
    SetConsoleActiveScreenBuffer(hConsole);

    if (startLetter == 'Y' || startLetter == 'y') {
        

        while (1) {
            //get input
            if (_kbhit()) {
                char key = _getch();
                if (key == leftKey) playerA -= 0.1f;
                if (key == rightKey) playerA += 0.1f;
                if (key == forwardKey) {
                    playerX += sinf(playerA) * 0.5f;
                    playerY += cosf(playerA) * 0.5f;
                    if (map[(int)playerY * MAP_WIDTH + (int)playerX] == '1') {
                        playerX -= sinf(playerA) * 0.5f;
                        playerY -= cosf(playerA) * 0.5f;
                    }
                }
                if (key == backKey) {
                    playerX -= sinf(playerA) * 0.5f;
                    playerY -= cosf(playerA) * 0.5f;
                    if (map[(int)playerY * MAP_WIDTH + (int)playerX] == '1') {
                        playerX += sinf(playerA) * 0.5f;
                        playerY += cosf(playerA) * 0.5f;
                    }
                }

                if (key == fireKey) {
                    fireWeapon();
                }

                if (key == menuKey) {
                    openMenu();
                }
            }

            //raycast and render into the screen buffer
            for (int x = 0; x < SCREEN_WIDTH; x++) {
                float rayAngle = (playerA - FOV / 2.0f) + ((float)x / (float)SCREEN_WIDTH) * FOV;

                float distanceToWall = 0;
                int hitWall = 0;
                float eyeX = sinf(rayAngle);
                float eyeY = cosf(rayAngle);

                while (!hitWall && distanceToWall < DEPTH) {
                    distanceToWall += 0.1f;
                    int testX = (int)(playerX + eyeX * distanceToWall);
                    int testY = (int)(playerY + eyeY * distanceToWall);

                    if (testX < 0 || testX >= MAP_WIDTH || testY < 0 || testY >= MAP_HEIGHT) {
                        hitWall = 1;
                         distanceToWall = DEPTH;
                    } else if (map[testY * MAP_WIDTH + testX] == '1') {
                        hitWall = 1;
                    }
                }

                int ceiling = (float)(SCREEN_HEIGHT / 2.0f) - SCREEN_HEIGHT / ((float)distanceToWall);
                int floor = SCREEN_HEIGHT - ceiling;

                for (int y = 0; y < SCREEN_HEIGHT; y++) {
                    int idx = y * SCREEN_WIDTH + x;

                    if (y < ceiling) {
                        screen[idx] = L' ';
                    } else if (y >= ceiling && y <= floor) {
                        //shade the wall based on distance
                        if (distanceToWall <= DEPTH / 4.0f)       screen[idx] = 0x2588; // very close block █
                        else if (distanceToWall < DEPTH / 3.0f)  screen[idx] = 0x2593; // dark shade ▓
                        else if (distanceToWall < DEPTH / 2.0f)  screen[idx] = 0x2592; // medium shade ▒
                        else if (distanceToWall < DEPTH)         screen[idx] = 0x2591; // light shade ░
                        else                                     screen[idx] = L' ';   // too far away
                    } else {
                        //floor shading
                        float b = 1.0f - (((float)y - SCREEN_HEIGHT / 2.0f) / (SCREEN_HEIGHT / 2.0f));
                        if (b < 0.25)      screen[idx] = '#';
                        else if (b < 0.5)  screen[idx] = 'x';
                        else if (b < 0.75) screen[idx] = '.';
                        else if (b < 0.9)  screen[idx] = '-';
                            else               screen[idx] = ' ';
                    }
                }
            }

            // draw the cross hair
            //get the middle values
            int centerX = SCREEN_WIDTH / 2;
            int centerY = SCREEN_HEIGHT / 2;

            //draw it
            screen[(centerY)     * SCREEN_WIDTH + centerX] = L'+';
            // screen[(centerY-1) * SCREEN_WIDTH + centerX] = L'|';
            // screen[(centerY+1) * SCREEN_WIDTH + centerX] = L'|';
            // screen[centerY * SCREEN_WIDTH + (centerX-1)] = L'-';
            // screen[centerY * SCREEN_WIDTH + (centerX+1)] = L'-';


            //print the buffer to console
            DWORD dwBytesWritten = 0;
            WriteConsoleOutputCharacterW(hConsole, screen, SCREEN_WIDTH * SCREEN_HEIGHT, (COORD){0,0}, &dwBytesWritten);

            Sleep(30);
        }
    }

    free(screen);
    return 0;
}
