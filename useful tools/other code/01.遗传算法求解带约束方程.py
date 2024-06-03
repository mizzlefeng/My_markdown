import random
from deap import base, creator, tools, algorithms

# 定义问题
creator.create("FitnessMin", base.Fitness, weights=(-1.0,))
creator.create("Individual", list, fitness=creator.FitnessMin)

toolbox = base.Toolbox()
toolbox.register("attr_x1", random.uniform, 90, 130)
toolbox.register("attr_x2", random.uniform, 0.04, 0.1)
toolbox.register("attr_x3", random.uniform, 0.1, 0.3)
toolbox.register("individual", tools.initCycle, creator.Individual,
                 (toolbox.attr_x1, toolbox.attr_x2, toolbox.attr_x3), n=1)
toolbox.register("population", tools.initRepeat, list, toolbox.individual)

# 修改后的评估函数
def evalFunc(individual):
    x1, x2, x3 = individual
    result = (-927.853 + 7.257 * x1 + 1992.257 * x2 - 562.604 * x3 + 
              1111.313 * x3**2 + 0.344 * x1 * x2 + 2.084 * x1 * x3)
    return (abs(result),)

toolbox.register("evaluate", evalFunc)
toolbox.register("mate", tools.cxBlend, alpha=0.5)
toolbox.register("mutate", tools.mutGaussian, mu=0, sigma=1, indpb=0.2)
toolbox.register("select", tools.selTournament, tournsize=3)

# 运行遗传算法
population = toolbox.population(n=300)
NGEN = 100
CXPB, MUTPB = 0.5, 0.3
for gen in range(NGEN):
    offspring = algorithms.varAnd(population, toolbox, cxpb=CXPB, mutpb=MUTPB)
    fits = toolbox.map(toolbox.evaluate, offspring)
    for fit, ind in zip(fits, offspring):
        ind.fitness.values = fit
    population = toolbox.select(offspring, len(population))

best_ind = tools.selBest(population, 1)[0]
print("Best individual is ", best_ind)
print("with fitness", best_ind.fitness.values[0])  # 这个值表示最接近0的函数值
