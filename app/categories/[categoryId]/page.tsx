import { getList, getCategory } from '@/libs/microcms';
import { LIMIT } from '@/constants';
import Pagination from '@/components/Pagination';
import ArticleList from '@/components/ArticleList';

type Props = {
  params: {
    categoryId: string;
  };
};

export const revalidate = 60;

export default async function Page({ params }: Props) {
  const { categoryId } = params;
  const data = await getList({
    limit: LIMIT,
    filters: `category[equals]${categoryId}`,
  });
  const category = await getCategory(categoryId);
  return (
    <>
      <ArticleList articles={data.contents} />
      <Pagination totalCount={data.totalCount} basePath={`/categories/${categoryId}`} />
    </>
  );
}
