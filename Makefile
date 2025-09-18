NAME=inception
COMPOSE= docker compose -f srcs/docker-compose.yml --env-file srcs/.env


.PHONY: all build up down logs stop clean fclean re prune


all: build up


build:
$(COMPOSE) build --no-cache


up:
$(COMPOSE) up -d


logs:
$(COMPOSE) logs -f --tail=200


stop:
$(COMPOSE) stop


down:
$(COMPOSE) down


clean: down
# Remove only containers and dangling images
docker image prune -f


fclean: down
# Remove volumes + images for this project
$(COMPOSE) down -v --rmi all --remove-orphans
docker volume prune -f


re: fclean all


prune:
docker system prune -af --volumes